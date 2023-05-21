// Dart imports:
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:spotify_dart/interfaces/spotify.dart';
import 'package:spotify_dart/interfaces/youtube.dart';
import 'package:spotify_dart/matcher.dart';
import 'package:spotify_dart/ui/components/result_grid_element.dart';

class UI extends StatefulWidget {
  const UI({super.key});

  @override
  State<UI> createState() => _UIState();
}

enum filter { toDownload, downloaded, skipped }

class _UIState extends State<UI> {
  var searchController = TextEditingController();

  var _songResults = <SimplifiedSongResult>[];

  var _playlistResults = <SimplifiedPlaylistResult>[];

  var _albumResults = <SimplifiedAlbumResult>[];

  bool _isLoading = true;

  /// songs yet to be downloaded
  var toDownload = <SimplifiedSongResult>[];

  /// songs that have been downloaded
  var downloaded = <SimplifiedSongResult>[];

  /// songs that have been skipped due to lack of confident matches
  var skipped = <SimplifiedSongResult>[];

  /// current song list filter
  var filterSelection = filter.toDownload;

  /// display theme
  var _themeMode = Brightness.dark;

  @override
  void initState() {
    // generate a random search query
    var charSet = 'abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789 ';

    var random = Random();
    var query = List.generate(
      5,
      (index) => charSet[random.nextInt(charSet.length)],
    ).join();

    updateResults(query: query);

    super.initState();
  }

  /// navigation rail infos/redirects
  _navInfos(int index) async {
    // if 'see code', open the github URL
    if (index == 0) {
      var _ = await launchUrl(Uri.parse('https://github.com/spotDL/spotdl-dart'));
    }

    // if 'about', open the about dialog
    else if (index == 1) {
      showAboutDialog(
        context: context,
        applicationName: 'spotDL',
        applicationVersion: '0.0.0-pre+15.may.23',
        applicationIcon: const Icon(Icons.library_music),
        applicationLegalese: '© 2023 shady-ti',
        children: [
          Text(
            'Songs are stored at ${Platform.isAndroid ? '/storage/emulated/0/spotdl' : (await getDownloadsDirectory())!.absolute.path}',
          )
        ],
      );
    }

    // toggle the theme
    else if (index == 2) {
      _themeMode = _themeMode == Brightness.dark ? Brightness.light : Brightness.dark;

      if (mounted) setState(() {});
    }
  }

  /// get the relevant list according the the currently chosen filter.
  List<SimplifiedSongResult> get relevantList {
    if (filterSelection == filter.toDownload) {
      return toDownload;
    } else if (filterSelection == filter.downloaded) {
      return downloaded;
    } else {
      return skipped;
    }
  }

  /// add a song to the download queue
  _addSongToQueue(String resultId) async {
    toDownload.add(await Spotify.getSong(songId: resultId));

    if (mounted) {
      setState(() {});
    }

    await _download();
  }

  /// add a playlist to the download queue
  _addPlaylistToQueue(String resultId) async {
    toDownload.addAll(await Spotify.getPlaylistTracks(playlistId: resultId));

    if (mounted) {
      setState(() {});
    }

    await _download();
  }

  /// add a album to the download queue
  _addAlbumToQueue(String resultId) async {
    toDownload.addAll(await Spotify.getAlbumTracks(albumId: resultId));

    if (mounted) {
      setState(() {});
    }

    await _download();
  }

  /// Download all songs in the download queue.
  Future<void> _download() async {
    // if there are songs in toDownload, download them
    var downloadDir = '';

    downloadDir = Platform.isAndroid
        ? '/storage/emulated/0/spotdl'
        : (await getDownloadsDirectory())!.absolute.path;

    while (toDownload.isNotEmpty) {
      var song = toDownload.first;

      var yResults = await YouTube.search(query: song.getSearchString());
      var bestMatch = await Matcher.findBestResult(sResult: song, yResults: yResults);

      if (bestMatch == null) {
        yResults = await YouTube.search(query: song.getMatchString());
        bestMatch = await Matcher.findBestResult(sResult: song, yResults: yResults);
      }

      if (bestMatch == null) {
        skipped.add(song);
      } else if (!downloaded.contains(song)) {
        try {
          await bestMatch.downloadTo(
            path: '$downloadDir/${song.getFileName()}.mp3',
          );
          downloaded.add(song);
        } catch (e) {
          skipped.add(song);
        }
      }

      var _ = toDownload.remove(song);

      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdaptiveScaffold(
        // destinations
        destinations: [
          const NavigationDestination(icon: Icon(Icons.logo_dev_outlined), label: 'See Code'),
          const NavigationDestination(icon: Icon(Icons.info_outline), label: 'About'),
          NavigationDestination(
            icon: Icon(_themeMode == Brightness.dark ? Icons.dark_mode : Icons.light_mode),
            label: _themeMode == Brightness.dark ? 'Dark Mode' : 'Light Mode',
          )
        ],

        // have no 'selected tab' highlights on the sidebar
        selectedIndex: null,

        // medium and abv
        body: (context) => Center(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: SearchBar(
                  controller: searchController,
                  hintText: 'Search for a song, album, or playlist',
                  trailing: [
                    IconButton(
                      onPressed: () => updateResults(query: searchController.text),
                      icon: const Icon(Icons.search_outlined),
                    ),
                  ],
                ),
              ),

              // Search Results
              _isLoading
                  ? const Expanded(child: Center(child: CircularProgressIndicator()))
                  : Expanded(
                      child: ListView(
                        children: [
                          ResultGridElement(
                            results: _songResults,
                            sliderTitle: 'Songs',
                            onClick: (resultId) => _addSongToQueue(resultId),
                          ),
                          ResultGridElement(
                            results: _playlistResults,
                            sliderTitle: 'Playlists',
                            onClick: (resultId) => _addPlaylistToQueue(resultId),
                          ),
                          ResultGridElement(
                            results: _albumResults,
                            sliderTitle: 'Albums',
                            onClick: (resultId) => _addAlbumToQueue(resultId),
                          ),
                        ],
                      ),
                    )
            ],
          ),
        ),
        secondaryBody: (context) => Column(
          children: [
            // filter
            Padding(
              padding: const EdgeInsets.all(20),
              child: SegmentedButton(
                segments: [
                  ButtonSegment(
                    value: filter.toDownload,
                    icon: const Icon(Icons.list),
                    label: filterSelection == filter.toDownload ? const Text('Queue') : null,
                  ),
                  ButtonSegment(
                    value: filter.downloaded,
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: filterSelection == filter.downloaded ? const Text('Done') : null,
                  ),
                  ButtonSegment(
                    value: filter.skipped,
                    icon: const Icon(Icons.next_plan_outlined),
                    label: filterSelection == filter.skipped ? const Text('Skipped') : null,
                  ),
                ],
                selected: {filterSelection},
                onSelectionChanged: (selection) => setState(() {
                  filterSelection = selection.first;
                }),
              ),
            ),

            //list
            Expanded(
              // Padding
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                // Download Cards
                child: ListView.builder(
                  itemBuilder: (context, index) => Card(
                    clipBehavior: Clip.hardEdge,
                    child: StreamBuilder<Object>(
                      stream: null,
                      builder: (context, snapshot) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Leading Image
                            Image.network(
                              relevantList.elementAt(index).artUrl,
                              width: 150,
                              height: 150,
                            ),

                            // Details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      relevantList.elementAt(index).title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      relevantList.elementAt(index).artists.join(', '),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                  itemCount: relevantList.length,
                ),
              ),
            )
          ],
        ),

        // panel split
        bodyRatio: 0.65,

        // sidebar behavior
        onSelectedIndexChange: _navInfos,
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: _themeMode,
        colorSchemeSeed: const Color.fromRGBO(115, 171, 132, 1),
      ),
    );
  }

  Future<void> updateResults({required String query}) async {
    setState(() {
      _isLoading = true;
    });

    _songResults = await Spotify.searchForSong(query: query);
    _playlistResults = await Spotify.searchForPlaylist(query: query);
    _albumResults = await Spotify.searchForAlbum(query: query);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

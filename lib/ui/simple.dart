// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:spotify_dart/interfaces/spotify.dart';
import 'package:spotify_dart/interfaces/youtube.dart';
import 'package:spotify_dart/matching/matcher.dart';

/// {@category UI}
///
/// A simple placeholder UI for download purposes only.

/// Sole page of the app.
class Simple extends StatefulWidget {
  const Simple({super.key});

  @override
  State<Simple> createState() => SimpleState();
}

enum filter { toDownload, downloaded, skipped }

class SimpleState extends State<Simple> {
  /// [TextEditingController] to take user input
  var controller = TextEditingController();

  /// songs yet to be downloaded
  var toDownload = <SimplifiedSResult>[];

  /// songs that have been downloaded
  var downloaded = <SimplifiedSResult>[];

  /// songs that have been skipped due to lack of confident matches
  var skipped = <SimplifiedSResult>[];

  /// current song list filter
  var filterSelection = filter.toDownload;

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
      );
    }
  }

  /// process the input and add [SimplifiedSResult]s to the [toDownload] list.
  void _processLink() async {
    var query = controller.text;

    // if playlist or album, add all tracks
    if (query.contains('/playlist')) {
      {
        toDownload.addAll(
          await Spotify.getPlaylistTracks(playlistId: query.split('/').last.split('?').first),
        );
      }
    } else if (query.contains('/album')) {
      toDownload.addAll(
        await Spotify.getAlbumTracks(albumId: query.split('/').last.split('?').first),
      );
    }

    // else treat the query as a search term
    else {
      toDownload.add((await Spotify.search(query: query)).first);
    }

    // reset text for next link
    controller.text = '';

    if (mounted) setState(() {});

    // if there are songs in toDownload, download them
    var downloadDir = (await getDownloadsDirectory())!.absolute.path;

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

  /// Just a wrapper around [_processLink] as `onSubmit` should have the same
  /// behavior.
  void _processLinkWrapper(String query) {
    _processLink();
  }

  /// get the relevant list according the the currently chosen filter.
  List<SimplifiedSResult> get relevantList {
    if (filterSelection == filter.toDownload) {
      return toDownload;
    } else if (filterSelection == filter.downloaded) {
      return downloaded;
    } else {
      return skipped;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      // side bar — see code, about
      destinations: const [
        NavigationDestination(icon: Icon(Icons.logo_dev_outlined), label: 'See Code'),
        NavigationDestination(icon: Icon(Icons.info_outline), label: 'About')
      ],

      // have no 'selected tab' highlights on the sidebar
      selectedIndex: null,

      // content
      // body small/medium — 1 col > list above, search below
      body: (context) => Column(
        children: [
          // filter
          Padding(
            padding: const EdgeInsets.all(40),
            child: SegmentedButton(
              segments: const [
                ButtonSegment(
                  value: filter.toDownload,
                  icon: Icon(Icons.list),
                  label: Text('Queue'),
                ),
                ButtonSegment(
                  value: filter.downloaded,
                  icon: Icon(Icons.download_for_offline_outlined),
                  label: Text('Done'),
                ),
                ButtonSegment(
                  value: filter.skipped,
                  icon: Icon(Icons.next_plan_outlined),
                  label: Text('Skipped'),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                itemBuilder: (context, index) => Card(
                  clipBehavior: Clip.hardEdge,
                  child: StreamBuilder<Object>(
                    stream: null,
                    builder: (context, snapshot) {
                      return Container(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              relevantList.elementAt(index).albumArtUrl,
                              width: 150,
                              height: 150,
                            ),
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
                        ),
                      );
                    },
                  ),
                ),
                itemCount: relevantList.length,
              ),
            ),
          ),

          // search
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Spotify link or search term . . .',
                      ),
                      autofocus: true,
                      onSubmitted: _processLinkWrapper,
                    ),
                  ),
                  IconButton(
                    onPressed: _processLink,
                    icon: const Icon(Icons.add),
                  )
                ],
              ),
            ),
          ),
        ],
      ),

      // desktop/web layout: 2col ? search center, list right (this is search)
      largeBody: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Spotify link or search term . . .',
                  ),
                  onSubmitted: _processLinkWrapper,
                ),
              ),
              IconButton(
                onPressed: _processLink,
                icon: const Icon(Icons.add),
              )
            ],
          ),
        ),
      ),

      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
      secondaryBody: AdaptiveScaffold.emptyBuilder,

      // desktop/web layout: 2col ? search center, list right (this is list)
      largeSecondaryBody: (context) => Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            // filter
            Padding(
              padding: const EdgeInsets.all(40),
              child: SegmentedButton(
                segments: const [
                  ButtonSegment(
                    value: filter.toDownload,
                    icon: Icon(Icons.list),
                    label: Text('Queue'),
                  ),
                  ButtonSegment(
                    value: filter.downloaded,
                    icon: Icon(Icons.download_for_offline_outlined),
                    label: Text('Done'),
                  ),
                  ButtonSegment(
                    value: filter.skipped,
                    icon: Icon(Icons.next_plan_outlined),
                    label: Text('Skipped'),
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
              child: ListView.builder(
                itemBuilder: (context, index) => Card(
                  clipBehavior: Clip.hardEdge,
                  child: StreamBuilder<Object>(
                    stream: null,
                    builder: (context, snapshot) {
                      return Container(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              relevantList.elementAt(index).albumArtUrl,
                              width: 150,
                              height: 150,
                            ),
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
                        ),
                      );
                    },
                  ),
                ),
                itemCount: relevantList.length,
              ),
            ),
          ],
        ),
      ),

      // main body ratio
      bodyRatio: 0.65,

      // layout change breakpoints
      smallBreakpoint: Breakpoints.small,
      mediumBreakpoint: const WidthPlatformBreakpoint(begin: 600, end: 1350),
      largeBreakpoint: const WidthPlatformBreakpoint(begin: 1350),

      // sidebar behavior
      onSelectedIndexChange: _navInfos,
    );
  }
}

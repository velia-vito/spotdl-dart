// Project imports:
import 'package:spotify_dart/interfaces/spotify.dart';
import 'package:spotify_dart/interfaces/youtube.dart';
import 'package:spotify_dart/matching/matcher.dart';

void main(List<String> args) async {
  for (var arg in args) {
    // if playlist, get tracks, download them.
    if (arg.contains('playlist')) {
      // e.g. https://open.spotify.com/playlist/0N26lkxX6XxG5o5Wk1R7MH?si=df871cd38d284051
      print('\n\nGetting playlist tracks from Spotify...');
      var tracks = await Spotify.getPlaylistTracks(
        playlistId: arg.split('/').last.split('?').first,
      );
      print('\tDone');

      for (var track in tracks) {
        await findAndDownload(track);
      }
    }

    // if album, do the same
    else if (arg.contains('album')) {
      // e.g. https://open.spotify.com/album/1e2o7O4xIRAo6pNBB5R5UA?si=f14fab31b2f34e1c
      print('\n\nGetting album tracks from Spotify...');
      var tracks = await Spotify.getAlbumTracks(
        albumId: arg.split('/').last.split('?').first,
      );
      print('\tDone');

      for (var track in tracks) {
        await findAndDownload(track);
      }
    }

    // otherwise treat it as a song query
    else {
      // find the first argument that starts on spotify
      print('\n\nSearching for ${args.first} on Spotify...');

      var sResult = (await Spotify.search(query: args.first)).first;
      print('\t$sResult');

      await findAndDownload(sResult);
    }
  }

  // finish
  print('\tDone');
}

/// find and download songs
// cuz main
// ignore: prefer-static-class
Future<void> findAndDownload(SimplifiedSResult song) async {
  // find the best match on YouTube
  print('\n\n>> Searching for ${song.getSearchString()} on YouTube...');
  var yResults = await YouTube.search(query: song.getSearchString());
  print('\tDone');

  print('   Narrowing down the results...');
  var bestMatch = await Matcher.findBestResult(sResult: song, yResults: yResults);

  if (bestMatch == null) {
    print('\tNo satisfactory results found, using alternate search criteria...');
    yResults = await YouTube.search(query: song.getMatchString());
    print('\tNarrowing down the results...');
    bestMatch = await Matcher.findBestResult(sResult: song, yResults: yResults);
  }

  // save the best match to disk
  if (bestMatch != null) {
    print('\t$bestMatch');

    // make file name and remove invalid characters (windows, linux, macOS, android, iOS)
    // var downloadPath = '${song.artists.join(', ')} - ${song.title}.mp3'.re;
    var downloadPath = '${song.artists.join(', ')} - ${song.title}.mp3'
        .replaceAll(r'/', '')
        .replaceAll(r'\', '')
        .replaceAll(r':', '')
        .replaceAll(r'*', '')
        .replaceAll(r'?', '')
        .replaceAll(r'"', '')
        .replaceAll(r'<', '')
        .replaceAll(r'>', '')
        .replaceAll(r'|', '');
    print('   Downloading to ./$downloadPath...');
    await bestMatch.downloadTo(path: downloadPath);
  } else {
    print('\tNo satisfactory results found ⚠️');
  }
}

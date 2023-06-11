// Dart imports:
import 'dart:io';

// Project imports:
import 'package:spotify_dart/interfaces/id3.dart';
import 'package:spotify_dart/interfaces/spotify.dart';
import 'package:spotify_dart/interfaces/youtube.dart';

void main(List<String> args) async {
  print('Obtainitng Platform specific ID3 instance . . .\n\n\n');
  var id3 = ID3.getId3Impl();

  for (var arg in args) {
    var id = '';

    if (arg.contains('track') || arg.contains('album') || arg.contains('playlist')) {
      //https://open.spotify.com/track/2UQYVFUrqybUciB3ULiysS?si=36a7b55b182a436d to 2UQYVFUrqybUciB3ULiysS
      id = arg.split('/').last.split('?').first;
    }

    var sResults = <SResultTrack>[];

    if (arg.contains('playlist')) {
      print('Obtaining Playlist Tracks . . .');
      sResults = await Spotify.getPlaylistTracks(playlistId: id);
    } else if (arg.contains('album')) {
      print('Obtaining Album Tracks . . .');
      sResults = await Spotify.getAlbumTracks(albumId: id);
    } else if (arg.contains('track')) {
      print('Obtaining Track . . .');
      sResults = [await Spotify.getTrack(trackId: id)];
    } else {
      print('Searching Spotify for query "$arg" . . .');
      sResults = [(await Spotify.searchForTrack(query: arg)).first];
    }

    print('\n\n\n');

    for (var sResult in sResults) {
      print('Searching YouTube for ${sResult.artists.join(', ')} - ${sResult.title} . . .');
      var yResult = await YouTube.getBestMatch(song: sResult);
      if (yResult != null) {
        print('Using ${yResult.author} - ${yResult.title} (${yResult.url}). . .');
      } else {
        print('No good match found . . .\n\tSkipping . . .');
        continue;
      }

      // Save the Audio and Album Art to file.
      var songPath = 'songs/${sResult.getSaveFileName()}';
      var albumArtPath = 'songs/albumArt.tmp';

      print('Downloading audio . . .');
      await yResult.downloadTo(path: songPath);

      // Write Metadata.
      print('Applying metadata . . .');
      await sResult.downloadAlbumArtTo(path: albumArtPath);

      id3.loadFile(path: songPath);
      var _ = await id3.writeMetadata(
        title: sResult.title,
        songArtists: sResult.artists,
        albumTitle: sResult.albumTitle,
        albumArtists: sResult.albumArtists,
        trackNumber: sResult.trackNumber,
        albumArtFilePath: albumArtPath,
      );

      print('\tDone\n\n\n');

      // Delete the temporary files.
      var __ = await File(albumArtPath).delete();
    }
  }
}

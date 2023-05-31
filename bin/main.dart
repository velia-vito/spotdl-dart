// Dart imports:
import 'dart:io';

// Project imports:
import 'package:spotify_dart/interfaces/id3.dart';
import 'package:spotify_dart/interfaces/spotify.dart';
import 'package:spotify_dart/interfaces/youtube.dart';

void main(List<String> args) async {
  // Find Song matches, download it.
  var sResult = await Spotify.getSong(songId: '69ySIzFcdu5MDs7CNNTLLk');
  var yResult = await YouTube.getBestMatch(song: sResult);

  // Save the Audio and Album Art to file.
  var songPath = sResult.getSaveFileName();
  var albumArtPath = 'albumArt.jpg';

  print('Downloading audio to $songPath . . .');
  await yResult!.downloadTo(path: songPath);
  print('\tDone');

  print('Downloading album art to albumArt.jpg . . .');
  await sResult.downloadAlbumArtTo(path: albumArtPath);
  print('\tDone');

  // Write Metadata.
  print('Obtaining Platform +specific ID3 implementation . . .');
  var id3 = ID3.getId3Impl();
  print('\tDone');

  print('Applying metadata . . .');
  id3.loadFile(path: songPath);
  var _ = await id3.writeMetadata(
    title: sResult.title,
    songArtists: sResult.artists,
    albumTitle: sResult.albumTitle,
    albumArtists: sResult.albumArtists,
    trackNumber: sResult.trackNumber,
    albumArtFilePath: albumArtPath,
  );
  print('\tDone');

  // Delete the temporary files.
  var __ = await File(albumArtPath).delete();
}

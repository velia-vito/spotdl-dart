import 'dart:io';

import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:ffmpeg_wasm/src/ffmpeg_extension.dart';

/// A wrapper around
class ID3 {
  String? albumArtUrl;

  static final _ffmpeg = createFFmpeg(CreateFFmpegParam());

  final _tagData = <String, String>{};

  late String _separator;

  String get separator => _separator;

  void setSeparator(String separator) {
    _separator = separator;
  }

  late String _currentFile;

  ID3({required String path, String separator = ', '}) {
    _currentFile = path;
    _separator = separator;
  }

  void loadFile({required String path}) {
    _currentFile = path;
  }

  void addTitle({required String title}) {
    _addTextTagFrame(tagName: 'title', tagValue: title);
  }

  void addSubtitle({required String subtitle}) {
    _addTextTagFrame(tagName: 'TIT3', tagValue: subtitle);
  }

  void addSongArtists({required List<String> artists}) {
    _addTextTagFrame(tagName: 'artist', tagValue: artists.join(_separator));
  }

  void addAlbumTitle({required String album}) {
    _addTextTagFrame(tagName: 'album', tagValue: album);
  }

  void addAlbumArtist({required List<String> artists}) {
    _addTextTagFrame(tagName: 'album_artist', tagValue: artists.join(_separator));
  }

  void addTrackNumber({required int trackNumber}) {
    _addTextTagFrame(tagName: 'track', tagValue: trackNumber.toString());
  }

  void addDiscNumber({required int discNumber}) {
    _addTextTagFrame(tagName: 'disc', tagValue: discNumber.toString());
  }

  void addAlbumYear({required int year}) {
    _addTextTagFrame(tagName: 'year', tagValue: year.toString());
  }

  void addGeneres({required List<String> generes}) {
    _addTextTagFrame(tagName: 'genre', tagValue: generes.join(_separator));
  }

  void addAlbumArt({required String url}) {
    albumArtUrl = url;
  }

  Future<void> writeTags() async {
    if (!_ffmpeg.isLoaded()) {
      var _ = await _ffmpeg.load();
    }

    // rename current file
    var _ = await File(_currentFile).rename('$_currentFile.tmp');

    // construct ffmpeg arguments
    var ffmpegArgs = '-i "$_currentFile.tmp"';

    // if album art is present
    if (albumArtUrl != null) {
      // download album art
      var albumArtRequest = await HttpClient().getUrl(Uri.parse(albumArtUrl!));
      var albumArtResponse = await albumArtRequest.close();
      var _ = await albumArtResponse.pipe(File('$_currentFile.jpg').openWrite());

      // add album art to ffmpeg arguments
      ffmpegArgs += ' -i "$_currentFile.jpg" -map 0:a -map 1:0'
          ' -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)"';
    } else {
      ffmpegArgs += ' -map 0:a';
    }

    // add text tags to ffmpeg arguments
    for (var element in _tagData.entries) {
      ffmpegArgs += ' -metadata ${element.key}="${element.value}"';
    }

    // add output file to ffmpeg arguments
    ffmpegArgs += ' "$_currentFile"';

    // run ffmpeg
    await _ffmpeg.runCommand(ffmpegArgs);
  }

  void _addTextTagFrame({required String tagName, required String tagValue}) {
    _tagData[tagName] = tagValue;
  }
}

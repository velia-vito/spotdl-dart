import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_cli/ffmpeg_cli.dart';

/// The interface implemented by classes that aid in editing ID3 tags.
abstract interface class ID3 {
  /// Character sequence used to separate artists, genres, etc.
  String get separator => throw UnimplementedError();

  /// Path the the file currently being edited.
  String get filePath => throw UnimplementedError();

  /// Set path of the file currently being edited.
  void loadFile({required String path}) => throw UnimplementedError();

  /// Utility function to set all metadata at the same time
  void setMetadata({
    String? title,
    String? comment,
    List<String>? songArtists,
    String? albumTitle,
    List<String>? albumArtists,
    int? trackNumber,
    int? discNumber,
    int? releaseYear,
    String? albumArtPath,
  }) =>
      throw UnimplementedError();

  /// Set title of the song.
  void addTitle({required String title}) => throw UnimplementedError();

  /// Add a comment to the song.
  void addComment({required String comment}) => throw UnimplementedError();

  /// Set the artists of the song.
  void addSongArtists({required List<String> artists}) => throw UnimplementedError();

  /// Set the title of the album to which this song belongs to.
  void addAlbumTitle({required String album}) => throw UnimplementedError();

  /// Set the album artists.
  void addAlbumArtist({required List<String> artists}) => throw UnimplementedError();

  /// Set the track number of the song in the album.
  void addTrackNumber({required int trackNumber}) => throw UnimplementedError();

  /// Set the disc number of the song (in case of a multi-disk album)
  void addDiscNumber({required int discNumber}) => throw UnimplementedError();

  /// Set the year of the song's parent-album release.
  void addAlbumReleaseYear({required int year}) => throw UnimplementedError();

  /// set the file at the given path as the song's album art
  void addAlbumArt({required String albumArtPath}) => throw UnimplementedError();
}

// -i "Yaeji — Raingurl-preEnc.mp3" -i rgc.jpg
// -map 0:a -codec copy -map 1:0
// -id3v2_version 3
// -metadata title="Raingurl"
// -metadata artist="Yaeji"
// -metadata album="Raingurl"
// -metadata album_artist="Yaeji||Bleh"
// -metadata date="2020"
// -metadata track="12"
// -metadata disk="2"
//  -metadata COMM="this is a test comment"
// -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)"
// "Yaeji — Raingurl.mp3"
/// ID3 editing for Windows, Linux, and MacOS via [Ffmpeg]
class ID3Desktop implements ID3 {
  static final ffmpeg = Ffmpeg();

  late String _separator;

  late String _filePath;

  @override
  String get separator => _separator;

  @override
  String get filePath => _filePath;

  /// Create an instance of [ID3Desktop]
  ID3Desktop({required String filePath, String separator = ', '}) : _filePath = filePath {
    _separator = separator;
  }
  @override
  Future<int> setMetadata({
    String? title,
    String? comment,
    List<String>? songArtists,
    String? albumTitle,
    List<String>? albumArtists,
    int? trackNumber,
    int? discNumber,
    int? releaseYear,
    String? albumArtPath,
  }) async {
    await _rename();

    var proc = Process.runSync(
      'ffmpeg',
      [
        //inputs
        '-i',
        '$_filePath.tmp',
        if (albumArtPath != null) '-i',
        if (albumArtPath != null) albumArtPath,
        if (albumArtPath != null) '-map',
        if (albumArtPath != null) '0:a',
        if (albumArtPath != null) '-map',
        if (albumArtPath != null) '1:0',

        // id3 version
        '-id3v2_version',
        '3',

        // album art
        if (albumArtPath != null) '-metadata:s:v',
        if (albumArtPath != null) 'title="Album cover"',
        if (albumArtPath != null) '-metadata:s:v',
        if (albumArtPath != null) 'comment="Cover (front)"',

        // other text frames
        if (title != null) '-metadata',
        if (title != null) 'title="$title"',

        if (comment != null) '-metadata',
        if (comment != null) 'COMM="$comment"',

        if (songArtists != null) '-metadata',
        if (songArtists != null) 'artist="${songArtists.join(separator)}"',

        if (albumTitle != null) '-metadata',
        if (albumTitle != null) 'album="$albumTitle"',

        if (albumArtists != null) '-metadata',
        if (albumArtists != null) 'album_artist="${albumArtists.join(separator)}"',

        if (trackNumber != null) '-metadata',
        if (trackNumber != null) 'track="$trackNumber"',

        if (discNumber != null) '-metadata',
        if (discNumber != null) 'disk="$discNumber"',

        if (releaseYear != null) '-metadata',
        if (releaseYear != null) 'date="$releaseYear"',

        // output
        _filePath,
      ],
    );

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  Future<int> addAlbumArt({required String albumArtPath}) async {
    await _rename();

    var proc = Process.runSync(
      'ffmpeg',
      [
        '-i',
        '$_filePath.tmp',
        '-i',
        albumArtPath,
        '-map',
        '0:a',
        '-map',
        '1:0',
        '-id3v2_version',
        '3',
        '-metadata:s:v',
        'title="Album cover"',
        '-metadata:s:v',
        'comment="Cover (front)"',
        _filePath,
      ],
    );

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  Future<int> addAlbumArtist({required List<String> artists}) async {
    await _rename();

    var proc = await Process.run('ffmpeg', [
      '-i',
      '$_filePath.tmp',
      '-id3v2_version',
      '3',
      '-metadata',
      'album_artist="${artists.join(separator)}"',
      _filePath,
    ]);

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  Future<int> addAlbumReleaseYear({required int year}) async {
    await _rename();

    var proc = await Process.run('ffmpeg', [
      '-i',
      '$_filePath.tmp',
      '-id3v2_version',
      '3',
      '-metadata',
      'date="$year"',
      _filePath,
    ]);

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  Future<int> addAlbumTitle({required String album}) async {
    await _rename();

    var proc = await Process.run('ffmpeg', [
      '-i',
      '$_filePath.tmp',
      '-id3v2_version',
      '3',
      '-metadata',
      'album="$album"',
      _filePath,
    ]);

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  Future<int> addComment({required String comment}) async {
    await _rename();

    var proc = await Process.run('ffmpeg', [
      '-i',
      '$_filePath.tmp',
      '-id3v2_version',
      '3',
      '-metadata',
      'COMM="$comment"',
      _filePath,
    ]);

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  Future<int> addDiscNumber({required int discNumber}) async {
    await _rename();

    var proc = await Process.run('ffmpeg', [
      '-i',
      '$_filePath.tmp',
      '-id3v2_version',
      '3',
      '-metadata',
      'disk="$discNumber"',
      _filePath,
    ]);

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  Future<int> addSongArtists({required List<String> artists}) async {
    await _rename();

    var proc = await Process.run('ffmpeg', [
      '-i',
      '$_filePath.tmp',
      '-id3v2_version',
      '3',
      '-metadata',
      'artist="${artists.join(separator)}"',
      _filePath,
    ]);

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  Future<int> addTitle({required String title}) async {
    await _rename();

    var proc = await Process.run('ffmpeg', [
      '-i',
      '$_filePath.tmp',
      '-id3v2_version',
      '3',
      '-metadata',
      'title="$title"',
      _filePath,
    ]);

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  Future<int> addTrackNumber({required int trackNumber}) async {
    await _rename();

    var proc = await Process.run('ffmpeg', [
      '-i',
      '$_filePath.tmp',
      '-id3v2_version',
      '3',
      '-metadata',
      'track="$trackNumber"',
      _filePath,
    ]);

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  void loadFile({required String path}) {
    _filePath = path;
  }

  Future<void> _rename() async {
    var _ = await File(filePath).rename('$filePath.tmp');
  }

  Future<void> _cleanUp() async {
    var _ = await File('$filePath.tmp').delete();
  }
}

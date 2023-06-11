part of '../id3.dart';

/// ID3 editing for Windows, Linux, and MacOS.
///
/// ### Note:
/// - Required ffmpeg to be installed and added to `PATH`
class ID3Desktop implements ID3Interface {
  late String _separator;

  late String _filePath;

  @override
  String get separator => _separator;

  @override
  String get filePath => _filePath;

  @override
  Future<int> writeMetadata({
    String? title,
    String? comment,
    List<String>? songArtists,
    String? albumTitle,
    List<String>? albumArtists,
    int? trackNumber,
    int? discNumber,
    int? releaseYear,
    String? albumArtFilePath,
  }) async {
    await _rename();

    var proc = await Process.run(
      'ffmpeg',
      [
        //inputs
        '-i',
        '$_filePath.tmp',
        if (albumArtFilePath != null) '-i',
        if (albumArtFilePath != null) albumArtFilePath,
        if (albumArtFilePath != null) '-map',
        if (albumArtFilePath != null) '0:a',
        if (albumArtFilePath != null) '-map',
        if (albumArtFilePath != null) '1:0',

        // id3 version
        '-id3v2_version',
        '3',

        // album art
        if (albumArtFilePath != null) '-metadata:s:v',
        if (albumArtFilePath != null) 'title=Album cover',
        if (albumArtFilePath != null) '-metadata:s:v',
        if (albumArtFilePath != null) 'comment=Cover (front)',

        // other text frames
        if (title != null) '-metadata',
        if (title != null) 'title=$title',

        if (comment != null) '-metadata',
        if (comment != null) 'COMM=$comment',

        if (songArtists != null) '-metadata',
        if (songArtists != null) 'artist=${songArtists.join(separator)}',

        if (albumTitle != null) '-metadata',
        if (albumTitle != null) 'album=$albumTitle',

        if (albumArtists != null) '-metadata',
        if (albumArtists != null) 'album_artist=${albumArtists.join(separator)}',

        if (trackNumber != null) '-metadata',
        if (trackNumber != null) 'track=$trackNumber',

        if (discNumber != null) '-metadata',
        if (discNumber != null) 'disk=$discNumber',

        if (releaseYear != null) '-metadata',
        if (releaseYear != null) 'date=$releaseYear',

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
        'title=Album cover',
        '-metadata:s:v',
        'comment=Cover (front)',
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
      'album_artist=${artists.join(separator)}',
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
      'date=$year',
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
      'album=$album',
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
      'COMM=$comment',
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
      'disk=$discNumber',
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
      'artist=${artists.join(separator)}',
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
      'title=$title',
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
      'track=$trackNumber',
      _filePath,
    ]);

    await _cleanUp();

    return proc.exitCode;
  }

  @override
  void loadFile({required String path, String separator = ', '}) {
    _filePath = path;
    _separator = separator;
  }

  Future<void> _rename() async {
    var _ = await File(filePath).rename('$filePath.tmp');
  }

  Future<void> _cleanUp() async {
    var _ = await File('$filePath.tmp').delete();
  }
}

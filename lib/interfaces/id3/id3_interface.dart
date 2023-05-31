part of '../id3.dart';

/// The interface implemented by classes that aid in editing ID3 tags.
abstract interface class ID3Interface {
  /// Character sequence used to separate artists, genres, etc.
  String get separator => throw UnimplementedError();

  /// Path the the file currently being edited.
  String get filePath => throw UnimplementedError();

  /// Set path of the file currently being edited.
  void loadFile({required String path}) => throw UnimplementedError();

  /// Utility function to set all metadata at the same time
  Future<void> writeMetadata({
    String? title,
    String? comment,
    List<String>? songArtists,
    String? albumTitle,
    List<String>? albumArtists,
    int? trackNumber,
    int? discNumber,
    int? releaseYear,
    String? albumArtFilePath,
  }) async =>
      throw UnimplementedError();

  /// Set title of the song.
  Future<void> addTitle({required String title}) async => throw UnimplementedError();

  /// Add a comment to the song.
  Future<void> addComment({required String comment}) async => throw UnimplementedError();

  /// Set the artists of the song.
  Future<void> addSongArtists({required List<String> artists}) async => throw UnimplementedError();

  /// Set the title of the album to which this song belongs to.
  Future<void> addAlbumTitle({required String album}) async => throw UnimplementedError();

  /// Set the album artists.
  Future<void> addAlbumArtist({required List<String> artists}) async => throw UnimplementedError();

  /// Set the track number of the song in the album.
  Future<void> addTrackNumber({required int trackNumber}) async => throw UnimplementedError();

  /// Set the disc number of the song (in case of a multi-disk album)
  Future<void> addDiscNumber({required int discNumber}) async => throw UnimplementedError();

  /// Set the year of the song's parent-album release.
  Future<void> addAlbumReleaseYear({required int year}) async => throw UnimplementedError();

  /// set the file at the given path as the song's album art
  Future<void> addAlbumArt({required String albumArtPath}) async => throw UnimplementedError();
}

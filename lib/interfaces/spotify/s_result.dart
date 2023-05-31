part of '../spotify.dart';

/// Base interface implemented by all Spotify result classes.
abstract interface class SResult {
  /// The title of the Song/Album/Playlist.
  String get title => throw UnimplementedError();

  /// The URL of the cover art of the Song/Album/Playlist.
  String get artUrl => throw UnimplementedError();

  /// The share-URL of the Song/Album/Playlist.
  String get url => throw UnimplementedError();

  /// The Spotify ID of the Song/Album/Playlist.
  String get id => throw UnimplementedError();

  /// The type of the Song/Album/Playlist as denoted by [SResultType].
  SResultType get type => throw UnimplementedError();

  /// The artists involved in the production the Song/Album/Playlist.
  List<String> get artists => throw UnimplementedError();
}

/// Type of Spotify results.
enum SResultType {
  /// denotes a [SResultSong]
  song,

  /// denotes a [SResultPlaylist]
  playlist,

  /// denotes a [SResultAlbum]
  album,
}

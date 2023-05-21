/// {@category Interfaces}
///
/// This file contains the [Spotify] and [SimplifiedSongResult] classes. These
/// simply interacting with Spotify.
///
/// ## Usage
///
/// ```dart
/// print('Searching Spotify for "Hiroyuki Sawano - blumenkrantz"...');
///
/// var songs = await Spotify.search(query: 'Hiroyuki Sawano - blumenkrantz');
///
/// for (var song in songs) {
///     print(song); // eg. SimplifiedSResult: Blumenkranz by Hiroyuki Sawano from キルラキル コンプリートサウンドトラック (258786 ms, https://open.spotify.com/track/1KvWQVn90Zfa1KdSuZXYxV)
/// }
///
/// print('Getting Tracks from Album "Moe Moe" by Moe Shop...');
///
/// var albumSongs = await Spotify.getAlbumTracks(albumId: '4cQMG9J5WiIDMYaWf5axzy');
///
/// for (var song in albumSongs) {
///     print(song); // eg. SimplifiedSResult: Magic by Moe Shop, MYLK from Moe Moe (209228 ms, https://open.spotify.com/track/4vDiYZOAGrt2eS3IYtkcgv)
/// }
///
/// print('Getting Tracks from Playlist "Old likes" by shady-ti...');
///
/// var playlistSongs = await Spotify.getPlaylistTracks(playlistId: '0N26lkxX6XxG5o5Wk1R7MH');
///
/// for (var song in playlistSongs) {
///     print(song); // eg. SimplifiedSResult: Revolving Door by Kisnou, Amethyst from All to Redeem (II) (210285 ms, https://open.spotify.com/track/25rwKmOxEqmbDH4PjlIZTS)
/// }
/// ```

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:spotify/spotify.dart';

/// Class simplifying interacting with Spotify.
class Spotify {
  /// The [SpotifyApi] instance used for interacting with Spotify.
  static final SpotifyApi intface = SpotifyApi(
    SpotifyApiCredentials(
      '5f573c9620494bae87890c0f08a60293',
      '212476d9b0f3472eaa762d90b19b0ba8',
    ),
  );

  /// Searches Spotify for the specified [query].
  static Future<List<SimplifiedSongResult>> searchForSong({
    required String query,
    int numberOfResults = 10,
  }) async {
    var results = await intface.search.get(query, types: [SearchType.track]).first(numberOfResults);

    var tracks = <SimplifiedSongResult>[];

    for (var page in results) {
      page.items?.forEach((track) {
        tracks.add(SimplifiedSongResult(track: track));
      });
    }

    return tracks;
  }

  static Future<List<SimplifiedPlaylistResult>> searchForPlaylist({
    required String query,
    int numberOfResults = 10,
  }) async {
    var results =
        await intface.search.get(query, types: [SearchType.playlist]).first(numberOfResults);

    var playlists = <SimplifiedPlaylistResult>[];

    for (var page in results) {
      for (var playlist in page.items ?? []) {
        playlists.add(
          SimplifiedPlaylistResult(
            playlist: await Spotify.intface.playlists.get(playlist.id!),
          ),
        );
      }
    }

    return playlists;
  }

  static Future<List<SimplifiedAlbumResult>> searchForAlbum(
      {required String query, int numberOfResults = 10}) async {
    var results = await intface.search.get(query, types: [SearchType.album]).first(numberOfResults);

    var albums = <SimplifiedAlbumResult>[];

    for (var page in results) {
      for (var album in page.items ?? []) {
        albums.add(SimplifiedAlbumResult(album: await Spotify.intface.albums.get(album.id!)));
      }
    }

    return albums;
  }

  /// Get all tracks from a playlist.
  static Future<List<SimplifiedSongResult>> getPlaylistTracks({required String playlistId}) async {
    var playlistTracks = await intface.playlists.getTracksByPlaylistId(playlistId).all();

    return playlistTracks.map((track) => SimplifiedSongResult(track: track)).toList();
  }

  /// Get all tracks from an album.
  static Future<List<SimplifiedSongResult>> getAlbumTracks({required String albumId}) async {
    // get all tracks from the album
    var simpleAlbumTracks = await intface.albums.getTracks(albumId).all();

    // use the tracks endpoint as the album endpoint returns partial track data
    var albumTracks = await intface.tracks.list(
      simpleAlbumTracks.map((simpleTrack) => simpleTrack.id!),
    );

    return albumTracks.map((track) => SimplifiedSongResult(track: track)).toList();
  }

  static Future<SimplifiedSongResult> getSong({required String songId}) async {
    var track = await intface.tracks.get(songId);

    return SimplifiedSongResult(track: track);
  }
}

/// Type of Spotify results.
enum SResultTypes {
  /// denotes a [SimpleSongResult]
  song,

  /// denotes a [SimplePlaylistResult]
  playlist,

  /// denotes a [SimpleAlbumResult]
  album,
}

/// Dummy utility class to be used to indicate any of [SimpleSongResult],
/// [SimplePlaylistResult], or [SimpleAlbumResult].
class SimplifiedSResult {
  String get title => throw UnimplementedError();
  String get artUrl => throw UnimplementedError();
  String get url => throw UnimplementedError();
  String get id => throw UnimplementedError();
  String get artist => throw UnimplementedError();
  SResultTypes get type => throw UnimplementedError();

  List<String> get artists => throw UnimplementedError();
}

/// Class simplifying locating Spotify song details.
///
/// Details exposed are:
/// - title
/// - artists (list)
/// - duration
/// - album
/// - url
class SimplifiedSongResult extends SimplifiedSResult {
  /// The full-fledged [Track] object.
  final Track track;

  /// Title of the track.
  @override
  String get title => track.name!;

  /// Artists of the track.
  @override
  List<String> get artists => track.artists!.map((e) => e.name!).toList();

  /// Album of the track.
  String get album => track.album!.name!;

  /// Duration of the track.
  Duration get duration => track.duration!;

  /// Duration of the track in milliseconds.
  int get durationMs => track.duration!.inMilliseconds;

  /// URL of the track.
  String get url => 'https://open.spotify.com/track/${track.id}';

  /// ID of the track.
  @override
  String get id => track.id!;

  /// Album art URL
  @override
  String get artUrl => track.album!.images!.first.url!;

  @override
  int get hashCode => toString().hashCode;

  /// Type of the result.
  @override
  SResultTypes get type => SResultTypes.song;

  /// Creates a new [SimplifiedSongResult] from a [Track].
  SimplifiedSongResult({required this.track});

  @override
  String toString() {
    return 'SimplifiedSResult: $title by ${artists.join(', ')} from "$album" ($durationMs ms, $url)';
  }

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }

  /// Return the string that is used for matching.
  String getMatchString() => '${artists.join(' ')} $title';

  /// Return the string that is used for the YouTube search query.
  String getSearchString() => '$title by ${artists.join(', ')} from "$album"';

  /// get filesystem safe file names
  ///
  /// ### Note
  /// - format used is: artist1, artist2, ... — title
  String getFileName() => '${artists.join(', ')} — $title'
      .replaceAll(r'/', '')
      .replaceAll(r'\', '')
      .replaceAll(r':', '')
      .replaceAll(r'*', '')
      .replaceAll(r'?', '')
      .replaceAll(r'"', '')
      .replaceAll(r'<', '')
      .replaceAll(r'>', '')
      .replaceAll(r'|', '');
}

/// Class simplifying locating Spotify playlist details.
///
/// Details exposed are:
/// - title
/// - artist (owner's display name)
/// - url
/// - art url
class SimplifiedPlaylistResult extends SimplifiedSResult {
  /// The full-fledged [Playlist] object.
  final Playlist playlist;

  /// Title of the playlist.
  @override
  String get title => playlist.name!;

  /// Owner of the playlist.
  @override
  List<String> get artists => [playlist.owner!.displayName!];

  /// URL of the playlist.
  String get url => 'https://open.spotify.com/playlist/${playlist.id}';

  /// ID of the playlist.
  @override
  String get id => playlist.id!;

  /// URL of the playlist's art.
  @override
  String get artUrl => playlist.images!.first.url!;

  /// Type of the result.
  @override
  SResultTypes get type => SResultTypes.playlist;

  /// Creates a new [SimplifiedPlaylistResult] from a [Playlist].
  SimplifiedPlaylistResult({required this.playlist});

  @override
  String toString() {
    return '$title (playlist) by $artist ($url)';
  }
}

/// Class simplifying locating Spotify album details.
class SimplifiedAlbumResult extends SimplifiedSResult {
  final Album album;

  String get title => album.name!;

  List<String> get artists => album.artists!.map((e) => e.name!).toList();

  String get url => 'https://open.spotify.com/album/${album.id}';

  @override
  String get id => album.id!;

  String get artUrl => album.images!.first.url!;

  SimplifiedAlbumResult({required this.album});
}

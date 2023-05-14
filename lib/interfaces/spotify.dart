/// {@category Interfaces}
///
/// This file contains the [Spotify] and [SimplifiedSResult] classes. These
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
  static Future<List<SimplifiedSResult>> search({
    required String query,
    int numberOfResults = 10,
  }) async {
    var results = await intface.search.get(query, types: [SearchType.track]).first(numberOfResults);

    var tracks = <SimplifiedSResult>[];

    for (var page in results) {
      page.items?.forEach((track) {
        tracks.add(SimplifiedSResult(track: track));
      });
    }

    return tracks;
  }

  /// Get all tracks from a playlist.
  static Future<List<SimplifiedSResult>> getPlaylistTracks({required String playlistId}) async {
    var playlistTracks = await intface.playlists.getTracksByPlaylistId(playlistId).all();

    return playlistTracks.map((track) => SimplifiedSResult(track: track)).toList();
  }

  /// Get all tracks from an album.
  static Future<List<SimplifiedSResult>> getAlbumTracks({required String albumId}) async {
    // get all tracks from the album
    var simpleAlbumTracks = await intface.albums.getTracks(albumId).all();

    // use the tracks endpoint as the album endpoint returns partial track data
    var albumTracks = await intface.tracks.list(
      simpleAlbumTracks.map((simpleTrack) => simpleTrack.id!),
    );

    return albumTracks.map((track) => SimplifiedSResult(track: track)).toList();
  }
}

/// Class simplifying locating Spotify result details.
///
/// Details exposed are:
/// - title
/// - artists (list)
/// - duration
/// - album
/// - url
///
class SimplifiedSResult {
  /// The full-fledged [Track] object.
  final Track track;

  /// Title of the track.
  String get title => track.name!;

  /// Artists of the track.
  List<String> get artists => track.artists!.map((e) => e.name!).toList();

  /// Album of the track.
  String get album => track.album!.name!;

  /// Duration of the track.
  Duration get duration => track.duration!;

  /// Duration of the track in milliseconds.
  int get durationMs => track.duration!.inMilliseconds;

  /// URL of the track.
  String get url => 'https://open.spotify.com/track/${track.id}';

  /// Album art URL
  String get albumArtUrl => track.album!.images!.first.url!;

  @override
  int get hashCode => toString().hashCode;

  /// Creates a new [SimplifiedSResult] from a [Track].
  SimplifiedSResult({required this.track});

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

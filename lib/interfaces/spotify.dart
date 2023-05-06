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

  /// Searches Spotify for the specified [query] and returns a list of [SimplifiedSResults]s.
  static Future<List<SimplifiedSResults>> Search(String query) async {
    var results = await intface.search.get(query, types: [SearchType.track]).first(5);

    var tracks = <SimplifiedSResults>[];

    results.forEach((page) {
      page.items?.forEach((track) {
        tracks.add(SimplifiedSResults(track));
      });
    });

    return tracks;
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
class SimplifiedSResults {
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

  /// Creates a new [SimplifiedSResults] from a [Track].
  SimplifiedSResults(this.track);

  @override
  String toString() {
    return 'SimplifiedSResult: $title by ${artists.join(', ')} from $album ($durationMs ms, $url)';
  }
}

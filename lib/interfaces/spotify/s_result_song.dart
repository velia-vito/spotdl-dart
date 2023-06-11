part of '../spotify.dart';

/// Class simplifying locating Spotify song details.
class SResultSong implements SResult {
  /// The full-fledged [Track] object.
  final Track track;

  @override
  String get title => track.name!;

  @override
  List<String> get artists => track.artists!.map((e) => e.name!).toList();

  /// Get all artists involved in the parent album.
  List<String> get albumArtists => track.album!.artists!.map((e) => e.name!).toList();

  /// Album of the track.
  String get albumTitle => track.album!.name!;

  /// Position of the track in the album.
  int get trackNumber => track.trackNumber!;

  /// Disc number in case of multi-disc albums.
  int get discNumber => track.discNumber!;

  /// Duration of the track.
  Duration get duration => track.duration!;

  /// Duration of the track in milliseconds.
  int get durationMs => duration.inMilliseconds;

  @override
  String get url => 'https://open.spotify.com/track/${track.id}';

  @override
  String get id => track.id!;

  @override
  String get artUrl => track.album!.images!.first.url!;

  @override
  int get hashCode => toString().hashCode;

  @override
  SResultType get type => SResultType.song;

  /// Creates a new [SResultSong] from a [Track].
  SResultSong({required this.track});

  @override
  String toString() {
    return '$title (song) by ${artists.join(', ')} from "$albumTitle" ($durationMs ms, $url)';
  }

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }

  /// Return the string that is used when trying to find the best result.
  String getYouTubeMatchingString() => '${artists.join(', ')} - $title';

  /// Return the string that is used for the YouTube search query.
  String getYouTubeSearchString() => '$title by ${artists.join(', ')} from "$albumTitle"';

  /// get filesystem safe file names
  ///
  /// ### Note
  /// - the returned file name already has `.mp3` appended.
  ///
  String getSaveFileName() => '${artists.join(', ')} — $title.mp3'
      .replaceAll(r'/', '')
      .replaceAll(r'\', '')
      .replaceAll(r':', '')
      .replaceAll(r'*', '')
      .replaceAll(r'?', '')
      .replaceAll(r'"', '')
      .replaceAll(r'<', '')
      .replaceAll(r'>', '')
      .replaceAll(r'|', '');

  /// Download the album art to a specified path.
  ///
  /// ### Note:
  /// - The file extension is **NOT** added automatically.
  Future<void> downloadAlbumArtTo({required String path}) async {
    // HTTP request data
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(Uri.parse(artUrl));
    var response = await request.close();

    // Write data to file
    var _ = await response.pipe(File(path).openWrite());

    httpClient.close();
  }
}

/// {@category Interfaces}
///
/// This file contains the [YouTube] and [SimplifiedYTEResult] classes. These
/// simply interacting with YouTube.
///
/// ## Usage
///
/// ```dart
/// print('Searching YouTube for "Hiroyuki Sawano - blumenkrantz"...');
///
/// var songs = await YouTube.search(query: 'Hiroyuki Sawano - blumenkrantz');
///
/// for (var song in songs) {
///     print(song); // eg. SimplifiedYTEResult: Blumenkranz by Various Artists - Topic (259000 ms) @ https://www.youtube.com/watch?v=zRI5uW6DLXg
/// }
/// ```

// Dart imports:
import 'dart:io';

// Package imports:
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Class simplifying interacting with YouTube Explode.
class YouTube {
  /// The [YoutubeExplode] instance used for interacting with YouTube.
  static final intface = YoutubeExplode();

  /// Searches YouTube for the specified [query].
  static Future<List<SimplifiedYTEResult>> search({required String query}) async {
    var results = await intface.search.search(query);

    return results.map((searchResult) => SimplifiedYTEResult(video: searchResult)).toList();
  }
}

/// Class simplifying locating YouTube Explode video details.
///
/// Details exposed are:
/// - title
/// - author
/// - duration
/// - url
/// - download function
///
class SimplifiedYTEResult {
  /// The full-fledged [Video] object.
  final Video video;

  /// Title of the video.
  String get title => video.title;

  /// Author/Uploader of the video.
  String get author => video.author;

  /// Duration of the video.
  Duration get duration => video.duration!;

  /// Duration of the video in milliseconds.
  int get durationMs => video.duration!.inMilliseconds;

  /// URL of the video.
  String get url => video.url.toString();

  /// Creates a new [SimplifiedYTEResult] from a [Video].
  SimplifiedYTEResult({required this.video});

  /// Downloads the audio to the specified [path].
  Future<void> downloadTo({required String path}) async {
    var yte = YoutubeExplode();

    // get the manifest and stream info
    var manifest = await yte.videos.streamsClient.getManifest(video.id);
    var streamInfo = manifest.audioOnly.withHighestBitrate();
    var stream = yte.videos.streamsClient.get(streamInfo);

    // download the video
    var file = File(path);
    file.createSync(recursive: true);
    var fileStream = file.openWrite();

    // !waiting for finish
    // ignore: avoid-ignoring-return-values
    await stream.pipe(fileStream);

    // !waiting for finish
    // ignore: avoid-ignoring-return-values
    await fileStream.flush();

    // !waiting for finish
    // ignore: avoid-ignoring-return-values
    await fileStream.close();
  }

  @override
  String toString() {
    return 'SimplifiedYTEResult: $title by $author ($durationMs ms, $url)';
  }

  /// Returns the string that is be used for matching.
  String getMatchString() => '$author - $title';
}

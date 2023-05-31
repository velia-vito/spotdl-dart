part of '../youtube.dart';

/// Class simplifying locating YouTube Explode video details.
class YResult {
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

  /// Creates a new [YResult] from a [Video].
  YResult({required this.video});

  /// Downloads the audio to the specified [path].
  ///
  /// Note:
  /// - No file extension is added, you need to include it in the [path].
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
    return '$title (video) by $author ($durationMs ms, $url)';
  }

  /// Returns the string that is be used for matching.
  String getMatchString() => '$author - $title';
}

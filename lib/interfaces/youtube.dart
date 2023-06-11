/// {@category Interfaces}
///
/// Simplifies interacting with YouTube.
///
/// ## Note
/// This library is designed with the express intention of finding song matches
/// between Spotify and YouTube results, and that is the reason the matching
/// algorithm/logic ([MatcherDefs]) is bound to this library instead of
/// separately.
///
/// ## Usage
///
/// [YouTube.getBestMatch] should cover 99% of your use cases.
///
/// ```dart
/// import 'package:spotify_dart/interfaces/spotify.dart';
/// import 'package:spotify_dart/interfaces/youtube.dart';
///
/// // NOTE: NOT AN EXHAUSTIVE EXAMPLE
/// void main(List<String> args) async {
///   var sResult = await Spotify.getSong(songId: '69ySIzFcdu5MDs7CNNTLLk');
///   var yResult = await YouTube.getBestMatch(song: sResult);
///
///   print('$sResult     <————(Matched With)————>     $yResult');
/// }
/// ```

// Dart imports:
import 'dart:io';
import 'dart:math';

// Package imports:
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Project imports:
import 'package:spotify_dart/interfaces/spotify.dart';

part 'youtube/y_result.dart';
part 'youtube/matcher_defs.dart';

/// Class simplifying interacting with YouTube Explode.
class YouTube {
  /// The [YoutubeExplode] instance used for interacting with YouTube.
  static final intface = YoutubeExplode();

  /// Searches YouTube for the specified [query].
  static Future<List<YResult>> search({required String query}) async {
    var results = await intface.search.search(query);

    if (results.isEmpty) {
      var queryElements = query.split(' ');
      var _ = queryElements.removeAt(Random().nextInt(queryElements.length));

      return search(query: queryElements.join(' '));
    } else {
      return results.map((searchResult) => YResult(video: searchResult)).toList();
    }
  }

  /// Finds the best match for the specified [SResultSong] on YouTube.
  static Future<YResult?> getBestMatch({required SResultSong song}) async {
    // Search with traditional search query.
    var bestMatch = await MatcherDefs.findBestResultAmong(
      sResult: song,
      yResults: await YouTube.search(query: song.getYouTubeSearchString()),
    );

    // If no good matches are found, use alternative search query.
    bestMatch ??= await MatcherDefs.findBestResultAmong(
      sResult: song,
      yResults: await YouTube.search(query: song.getYouTubeMatchingString()),
    );

    return bestMatch;
  }
}

/// {@category Core}
///
/// This file contains the [Matcher] class that holds the requisite methods to
/// find the best possible match for any given Spotify track on YouTube.
///
/// ## Usage
///
/// ```dart
/// var sResult = await Spotify.search(query: 'Hiroyuki Sawano - blumenkrantz');
/// var yResultSet = await YouTube.search(query: sResult.getSearchString());
///
/// print((await Matcher.findBestResult(sResult: sResult, yResults: yResultSet)));
/// ```

// Dart imports:
import 'dart:math';

// Project imports:
import 'package:spotify_dart/interfaces/spotify.dart';
import 'package:spotify_dart/interfaces/youtube.dart';

/// The [Matcher] class contains methods to to narrow down a multitude of YouTube
/// results in the form of [SimplifiedYTEResult]s to the single best match to
/// the given Spotify metadata in the form of a [SimplifiedSResult].
class Matcher {
  /// Reduce a list of [SimplifiedYTEResult]s to a single `SimplifiedYTEResult`
  /// that best matches the provided [SimplifiedSResult].
  static Future<SimplifiedYTEResult?> findBestResult({
    required SimplifiedSResult sResult,
    required List<SimplifiedYTEResult> yResults,
  }) async {
    var bResult = yResults.first;
    var bMatchScore = await matchScore(sResult: sResult, yResult: bResult);

    for (var yResult in yResults) {
      // update best result if current result is better
      var yMatchScore = await matchScore(sResult: sResult, yResult: yResult);

      if (yMatchScore > bMatchScore) {
        bMatchScore = yMatchScore;
        bResult = yResult;
      }

      // else perform a tie-breaker if the results are tied
      else if (yMatchScore == bMatchScore) {
        // skip tie-breaker if one of the results is a "Topic" channel
        if (bResult.author.endsWith('- Topic') && !yResult.author.endsWith('- Topic')) {
          continue;
        } else if (yResult.author.endsWith('- Topic') && !bResult.author.endsWith('- Topic')) {
          bResult = yResult;
          continue;
        }

        // Calculate tie-breaker score for current result.
        var yTimeDiff = (sResult.durationMs - yResult.durationMs).abs() / 15000;
        var yNameDiff = await overlapCoefficient(
          s1: sResult.getMatchString(),
          s2: yResult.getMatchString(),
          tightMatching: true,
        );
        var yTieBreakerScore = yNameDiff - yTimeDiff;

        // Calculate tie-breaker score for best result.
        var bTimeDiff = (sResult.durationMs - bResult.durationMs).abs() / 15000;
        var bNameDiff = await overlapCoefficient(
          s1: sResult.getMatchString(),
          s2: bResult.getMatchString(),
          tightMatching: true,
        );
        var bTieBreakerScore = bNameDiff - bTimeDiff;

        // If current result has a better tie-breaker score, replace best result.
        if (yTieBreakerScore > bTieBreakerScore) {
          bResult = yResult;
        }
      }
    }

    // if the best result has a match score of 1 or lesser it means that it's
    // either a purely duration based or name based match. That's not a good
    // enough basis for surety.
    return bMatchScore > 1 ? bResult : null;
  }

  /// Calculate a match score between two a [SimplifiedSResult] and a
  /// [SimplifiedYTEResult].
  static Future<int> matchScore({
    required SimplifiedSResult sResult,
    required SimplifiedYTEResult yResult,
  }) async {
    var score = 0;

    // if duration is within 15s, score + 1, else exit
    if ((sResult.durationMs - yResult.durationMs).abs() < 15000) {
      score++;
    } else {
      return score; // exit.
    }

    // if songs are different versions, score = 0
    var sMatch = sResult.getMatchString().toLowerCase();
    var yMatch = yResult.getMatchString().toLowerCase();

    // avoid mixing up vocal and instrumental versions
    for (var term in [
      'karaoke',
      'instrumental',
      'vocal',
      'cover',
      'remix',
      'version',
      'audio only',
      'only audio',
    ]) {
      if ((sMatch.contains(term) && !yMatch.contains(term)) ||
          (yMatch.contains(term) && !sMatch.contains(term))) {
        return 0;
      }
    }

    // if constructed titles are similar, score + 1
    if (await overlapCoefficient(
          s1: sMatch,
          s2: yMatch,
        ) >
        0.75) {
      score++;
    }

    // if uploader and artist are similar, or it belongs to a YouTube topic
    // channel, score + 1
    if (yResult.author.endsWith('- Topic')) {
      score++;
    } else {
      for (var artist in sResult.artists) {
        if (await isSimilar(s1: artist, s2: yResult.author)) {
          score++;
          break;
        }
      }
    }

    return score;
  }

  /// calculate the Overlap coefficient between two sentences
  ///
  /// ### Args
  /// - `tightMatching` - if true, only 1 letter difference is tolerated instead
  /// of the usual 2 letter difference.
  ///
  /// ### Note
  /// - The fancy name is [Szymkiewicz–Simpson Coefficient](https://en.wikipedia.org/wiki/Overlap_coefficient).
  ///
  /// - Strings are lowercased before comparison.
  ///
  /// - Up to and including two letter differences between words are ignored
  /// (usually).
  static Future<double> overlapCoefficient({
    required String s1,
    required String s2,
    bool tightMatching = false,
  }) async {
    // "Moe Shop - Moe Shop - Love Taste (w/ Jamie Paige & Shiki)" creates
    // "(w/" and "shiki)" as elements. Adjustments to avoid such situations.
    s1 = s1.toLowerCase().replaceAll('(', ' ( ').replaceAll(')', ' ) ');
    s2 = s2.toLowerCase().replaceAll('(', ' ( ').replaceAll(')', ' ) ');

    // split the strings into words (empty and single character elements are
    // removed to eliminate things like "", "-", "&", etc.)
    var set1 = s1.split(' ').toSet()..removeWhere((element) => element.length < 2);
    var set2 = s2.split(' ').toSet()..removeWhere((element) => element.length < 2);

    // get intersection of words
    var intersection = <String>{};

    for (var word1 in set1) {
      for (var word2 in set2) {
        if (await isSimilar(s1: word1, s2: word2, tightMatching: tightMatching)) {
          var _ = intersection.add(word1);
        }
      }
    }

    var overlapScore = intersection.length / min(set1.length, set2.length);

    // as we ignore up to two letter differences, the intersection can be
    // greater than the smaller set which would cause errors, so in such a case
    // we use tighter matching. eg. s1 = {'door', 'mood'} and s2 = {'door'},
    // then the s1 ∩ S2 = {'door', 'mood'}
    return overlapScore > 1
        ? await overlapCoefficient(s1: s1, s2: s2, tightMatching: true)
        : overlapScore;
  }

  /// check if two strings are similar (up to 2 letter differences are ignored)
  ///
  /// ### Args
  /// - `tightMatching` - if true, only 1 letter difference is tolerated.
  static Future<bool> isSimilar({
    required String s1,
    required String s2,
    bool tightMatching = false,
  }) async {
    // if the strings are the same, return true
    if (s1 == s2) {
      return true;
    }
    // if the strings are different lengths, return false
    else if (s1.length != s2.length) {
      return false;
    }
    // else tolerate up to 2 letter differences (usually)
    // we use the tighter 1 letter difference for tie-breakers
    else {
      int diffCount = 0;

      for (int i = 0; i < s1.length; i++) {
        if (s1[i] != s2[i]) diffCount++;
        if (diffCount > (tightMatching ? 1 : 2)) return false;
      }

      return true;
    }
  }
}

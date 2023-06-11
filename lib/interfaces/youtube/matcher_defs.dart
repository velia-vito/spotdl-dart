part of '../youtube.dart';

/// The underlying logic that is used to assign a match score to each [YResult].
///
/// Note:
/// - Higher scores are better.
class MatcherDefs {
  /// Reduce a list of [YResult]s to a single `SimplifiedYTEResult`
  /// that best matches the provided [SResultTrack].
  static Future<YResult?> findBestResultAmong({
    required SResultTrack sResult,
    required List<YResult> yResults,
  }) async {
    if (yResults.isEmpty) {
      throw Exception('No YouTube results provided.');
    }

    var bResult = yResults.first;
    var bMatchScore = await calculateMatchScore(sResult: sResult, yResult: bResult);

    for (var yResult in yResults) {
      // update best result if current result is better
      var yMatchScore = await calculateMatchScore(sResult: sResult, yResult: yResult);

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
          s1: sResult.getYouTubeMatchingString(),
          s2: yResult.getMatchString(),
          tightMatching: true,
        );
        var yTieBreakerScore = yNameDiff - yTimeDiff;

        // Calculate tie-breaker score for best result.
        var bTimeDiff = (sResult.durationMs - bResult.durationMs).abs() / 15000;
        var bNameDiff = await overlapCoefficient(
          s1: sResult.getYouTubeMatchingString(),
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

    // if the best result has a match score of 0.75 or lesser it means that it's
    // either a purely duration based or name based match. That's not a good
    // enough basis for surety.
    return bMatchScore > 0.75 ? bResult : null;
  }

  /// Calculate a match score between two a [SResultTrack] and a
  /// [YResult].
  static Future<double> calculateMatchScore({
    required SResultTrack sResult,
    required YResult yResult,
  }) async {
    var score = 0.0;

    // if songs are different versions, score = 0
    var sMatch = sResult.getYouTubeMatchingString().toLowerCase();
    var yMatch = yResult.getMatchString().toLowerCase();

    // avoid mixing up vocal and instrumental versions
    for (var term in [
      'karaoke',
      'instrumental',
      'vocal',
      'cover',
      'remix',
      'slowed',
      'reverb',
      'version',
      'mix',
      'audio only',
      'only audio',
    ]) {
      if ((sMatch.contains(term) ^ yMatch.contains(term))) {
        return 0;
      }
    }

    // if duration is within 10s, score + 1, else exit
    var timeDelta = (sResult.durationMs - yResult.durationMs).abs();
    if (timeDelta < 10000) {
      score += 1 - (timeDelta / 10000);
    } else {
      return 0; // exit.
    }

    // if constructed titles are similar, score + 1
    var overlapCoeff = await overlapCoefficient(
      s1: sMatch,
      s2: yMatch,
    );

    var greenCardVideoAuthor = yResult.author.endsWith('- Topic') ||
        yResult.author.endsWith('Label') ||
        yResult.author.endsWith('Records');

    if (overlapCoeff >= 0.33 || greenCardVideoAuthor) {
      score += overlapCoeff;
    } else {
      return 0;
    }

    // if uploader and artist are similar, or it belongs to a YouTube topic
    // channel, score + 1
    if (greenCardVideoAuthor) {
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
  /// - The fancy name is [Tanimoto Index](https://en.wikipedia.org/wiki/Jaccard_index).
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

    for (var char in ['(', ')', '[', ']', '【', '】', '{', '}', '-', '&']) {
      s1 = s1.replaceAll(char, '');
      s2 = s2.replaceAll(char, '');
    }

    // split the strings into words (empty and single character elements are
    // removed to eliminate things like "", "-", "&", etc.)
    var set1 = s1.split(' ').toSet()..removeWhere((element) => element.length < 2);
    var set2 = s2.split(' ').toSet()..removeWhere((element) => element.length < 2);

    // get intersection of words
    var intersection = <String>{};
    var union = <String>{}..addAll(set1);

    for (var word1 in set1) {
      for (var word2 in set2) {
        if (await isSimilar(s1: word1, s2: word2, tightMatching: tightMatching)) {
          var _ = intersection.add(word1);
        } else {
          var _ = union.add(word2);
        }
      }
    }

    var overlapScore = intersection.length / union.length;

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
      // print('isSimilar:\n\t$s1\n\t$s2\n\tfalse');
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
      // print('isSimilar:\n\t$s1\n\t$s2\n\ttrue');
      return true;
    }
  }
}

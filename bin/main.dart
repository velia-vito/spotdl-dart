// Project imports:
import 'package:spotify_dart/interfaces/spotify.dart';
import 'package:spotify_dart/interfaces/youtube.dart';
import 'package:spotify_dart/matcher.dart';

void main(List<String> args) async {
  // find the first argument that starts on spotify
  print('\n\n1. Searching for ${args.first} on Spotify...');

  var sResult = (await Spotify.search(query: args.first)).first;
  print('\t$sResult');

  // find the best match on YouTube
  print('\n\n2. Searching for ${sResult.getSearchString()} on YouTube...');
  var yResults = await YouTube.search(query: sResult.getSearchString());
  print('\tDone');

  print('\n\n3. Narrowing down the results...');
  var bestMatch = await Matcher.findBestResult(sResult: sResult, yResults: yResults);

  if (bestMatch == null) {
    print('\tNo satisfactory results found, using alternate search criteria...');
    yResults = await YouTube.search(query: sResult.getMatchString());
    print('\tNarrowing down the results...');
    bestMatch = await Matcher.findBestResult(sResult: sResult, yResults: yResults);
  }

  // save the best match to disk
  if (bestMatch != null) {
    print('\t$bestMatch');
    print('\n\n4. Downloading to ./${sResult.artists.join(', ')} - ${sResult.title}.mp3...');
    await bestMatch.downloadTo(path: '${sResult.artists.join(', ')} - ${sResult.title}.mp3');
  } else {
    print('\tNo satisfactory results found ⚠️');
  }

  print('\tDone');
}

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:spotify_dart/ui/ui.dart';

import 'interfaces/id3.dart';

void main(List<String> args) {
  runApp(
    MaterialApp(
      home: const UI(),
      theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: const Color.fromRGBO(115, 171, 132, 1)),
    ),
  );

  var artUrl = 'https://i.scdn.co/image/ab67616d0000b273248731c083c4b81d7a0cf0e1';
  var id3 = ID3(path: './SpaceyBlurr — Tits');

  id3.addTitle(title: 'Tits');
  id3.addAlbumTitle(album: 'Tits');
  id3.addTrackNumber(trackNumber: 1);
  id3.addAlbumArt(url: artUrl);
  id3.addAlbumArtist(artists: ['SpaceyBlurr']);
  id3.addSongArtists(artists: ['SpaceyBlurr']);
  id3.addAlbumYear(year: 2023);
  id3.addDiscNumber(discNumber: 1);
  id3.addSubtitle(
      subtitle: 'Spotify: https://open.spotify.com/track/5qnIdcfSRI8cDHuOu6ATat,'
          ' Youtube: https://www.youtube.com/watch?v=t_41SN3Xreg&pp=ygUQU3BhY2V5Qkx1cnIgdGl0cw%3D%3D');

  id3.writeTags().then((value) => print('done'));
}

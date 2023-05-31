part of '../spotify.dart';

/// Class simplifying locating Spotify album details.
class SResultAlbum implements SResult {
  final Album album;

  @override
  String get title => album.name!;

  @override
  List<String> get artists => album.artists!.map((e) => e.name!).toList();

  @override
  String get url => 'https://open.spotify.com/album/${album.id}';

  @override
  String get id => album.id!;

  @override
  String get artUrl => album.images!.first.url!;

  @override
  SResultType get type => SResultType.album;

  /// Creates a new [SResultAlbum] from a [Album].
  SResultAlbum({required this.album});

  @override
  String toString() {
    return '$title (album) by ${artists.join(', ')} ($url)';
  }
}

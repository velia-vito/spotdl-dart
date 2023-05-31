part of '../spotify.dart';

/// Class simplifying locating Spotify playlist details.
///
/// Details exposed are:
/// - title
/// - artist (owner's display name)
/// - url
/// - art url
class SResultPlaylist implements SResult {
  /// The full-fledged [Playlist] object.
  final Playlist playlist;

  @override
  String get title => playlist.name!;

  @override
  List<String> get artists => [playlist.owner!.displayName!];

  @override
  String get url => 'https://open.spotify.com/playlist/${playlist.id}';

  @override
  String get id => playlist.id!;

  @override
  String get artUrl => playlist.images!.first.url!;

  @override
  SResultType get type => SResultType.playlist;

  /// Creates a new [SResultPlaylist] from a [Playlist].
  SResultPlaylist({required this.playlist});

  @override
  String toString() {
    return '$title (playlist) by $artists ($url)';
  }
}

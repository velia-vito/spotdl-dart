/// {@category Interfaces}
///
/// Simplifying interactions with Spotify.
///
/// ## Usage
///
/// Most of your needs can be met by just the [Spotify] class.
///
/// ```dart
/// import 'package:spotify_dart/interfaces/spotify.dart';
///
/// // NOTE: NOT AN EXHAUSTIVE EXAMPLE
/// void main(List<String> args) async {
///
///   // Searching for songs by query.
///   print('Songs:');
///   var songResults = await Spotify.searchForSong(query: 'Solar Fields — Heat');
///   songResults.forEach((song) {
///     print('\n\t- $song');
///   });
///
///   // Searching for albums by query.
///   print('\n\n\nAlbums:');
///   var albumResults = await Spotify.searchForAlbum(query: 'Sarah Schachner — Anthem');
///   albumResults.forEach((album) {
///     print('\n\t- $album');
///   });
///
///   // Searching for playlists by query.
///   print('\n\n\nPlaylists:');
///   var playlistResults = await Spotify.searchForPlaylist(query: 'Death Stranding');
///   playlistResults.forEach((playlist) {
///     print('\n\t- $playlist');
///   });
/// }
/// ```

// Dart imports:
import 'dart:io';

// Package imports:
import 'package:spotify/spotify.dart';

part 'spotify/s_result.dart';
part 'spotify/s_result_song.dart';
part 'spotify/s_result_album.dart';
part 'spotify/s_result_playlist.dart';

/// Class simplifying interacting with Spotify.
class Spotify {
  /// The [SpotifyApi] instance used for interacting with Spotify.
  static final SpotifyApi intface = SpotifyApi(
    SpotifyApiCredentials(
      '5f573c9620494bae87890c0f08a60293',
      '212476d9b0f3472eaa762d90b19b0ba8',
    ),
  );

  /// Searches Spotify for songs that match the specified [query].
  static Future<List<SResultTrack>> searchForTrack({
    required String query,
    int numberOfResults = 10,
  }) async {
    var results = await intface.search.get(query, types: [SearchType.track]).first(numberOfResults);

    var tracks = <SResultTrack>[];

    for (var page in results) {
      page.items?.forEach((track) {
        tracks.add(SResultTrack(track: track));
      });
    }

    return tracks;
  }

  /// Searches Spotify for playlists that match the specified [query].
  static Future<List<SResultPlaylist>> searchForPlaylist({
    required String query,
    int numberOfResults = 10,
  }) async {
    var results =
        await intface.search.get(query, types: [SearchType.playlist]).first(numberOfResults);

    var playlists = <SResultPlaylist>[];

    for (var page in results) {
      for (var playlist in page.items ?? []) {
        playlists.add(
          SResultPlaylist(
            playlist: await Spotify.intface.playlists.get(playlist.id!),
          ),
        );
      }
    }

    return playlists;
  }

  /// Searches Spotify for albums that match the specified [query].
  static Future<List<SResultAlbum>> searchForAlbum(
      {required String query, int numberOfResults = 10}) async {
    var results = await intface.search.get(query, types: [SearchType.album]).first(numberOfResults);

    var albums = <SResultAlbum>[];

    for (var page in results) {
      for (var album in page.items ?? []) {
        albums.add(SResultAlbum(album: await Spotify.intface.albums.get(album.id!)));
      }
    }

    return albums;
  }

  /// Get all tracks from a playlist.
  static Future<List<SResultTrack>> getPlaylistTracks({required String playlistId}) async {
    var playlistTracks = await intface.playlists.getTracksByPlaylistId(playlistId).all();

    return playlistTracks.map((track) => SResultTrack(track: track)).toList();
  }

  /// Get all tracks from an album.
  static Future<List<SResultTrack>> getAlbumTracks({required String albumId}) async {
    // get all tracks from the album
    var simpleAlbumTracks = await intface.albums.getTracks(albumId).all();

    // use the tracks endpoint as the album endpoint returns partial track data
    var albumTracks = await intface.tracks.list(
      simpleAlbumTracks.map((simpleTrack) => simpleTrack.id!),
    );

    return albumTracks.map((track) => SResultTrack(track: track)).toList();
  }

  /// Get a song from its ID.
  static Future<SResultTrack> getTrack({required String trackId}) async {
    var track = await intface.tracks.get(trackId);

    return SResultTrack(track: track);
  }

  /// Get an album from its ID.
  static Future<SResultAlbum> getAlbum({required String albumId}) async {
    var album = await intface.albums.get(albumId);

    return SResultAlbum(album: album);
  }

  /// Get a playlist from its ID.
  static Future<SResultPlaylist> getPlaylist({required String playlistId}) async {
    var playlist = await intface.playlists.get(playlistId);

    return SResultPlaylist(playlist: playlist);
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/simpmusic_response.dart';

/// SimpMusic lyrics provider.
///
/// Fetches lyrics from https://api-lyrics.simpmusic.org API using YouTube video IDs.
class SimpMusicLyrics {
  static const String _baseUrl = 'https://api-lyrics.simpmusic.org/v1/';

  final http.Client _client;

  /// Create a new SimpMusicLyrics instance
  SimpMusicLyrics({http.Client? client}) : _client = client ?? http.Client();

  /// Get lyrics by YouTube video ID
  ///
  /// Returns a list of all matching lyrics data.
  Future<List<SimpMusicLyricsData>> getLyricsByVideoId(String videoId) async {
    try {
      final uri = Uri.parse('$_baseUrl$videoId');

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'SimpMusicLyrics/1.0',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final apiResponse = SimpMusicApiResponse.fromJson(json);
        if (apiResponse.success) {
          return apiResponse.data;
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get best matching lyrics for a video
  ///
  /// Returns the lyrics text or throws an exception if unavailable.
  ///
  /// Parameters:
  /// - [videoId]: YouTube video ID
  /// - [duration]: Optional track duration in seconds for better matching
  Future<String> getLyrics({
    required String videoId,
    int duration = 0,
  }) async {
    final tracks = await getLyricsByVideoId(videoId);

    if (tracks.isEmpty) {
      throw Exception('Lyrics unavailable');
    }

    SimpMusicLyricsData? bestMatch;

    if (duration > 0 && tracks.length > 1) {
      // Find best match by duration
      var minDiff = double.infinity;
      for (final track in tracks) {
        final diff = ((track.duration ?? 0) - duration).abs();
        if (diff < minDiff) {
          minDiff = diff.toDouble();
          bestMatch = track;
        }
      }
    } else {
      bestMatch = tracks.first;
    }

    final lyrics = bestMatch?.syncedLyrics ?? bestMatch?.plainLyrics;
    if (lyrics == null) {
      throw Exception('Lyrics unavailable');
    }

    return lyrics;
  }

  /// Get all matching lyrics with callback
  ///
  /// Calls the callback for each matching lyrics found (up to 5).
  ///
  /// Parameters:
  /// - [videoId]: YouTube video ID
  /// - [duration]: Optional track duration in seconds
  /// - [callback]: Function called for each lyrics found
  Future<void> getAllLyrics({
    required String videoId,
    int duration = 0,
    required void Function(String lyrics) callback,
  }) async {
    final tracks = await getLyricsByVideoId(videoId);

    var count = 0;
    var plain = 0;

    List<SimpMusicLyricsData> sortedTracks;

    if (duration > 0) {
      sortedTracks = List<SimpMusicLyricsData>.from(tracks)
        ..sort((a, b) => ((a.duration ?? 0) - duration)
            .abs()
            .compareTo(((b.duration ?? 0) - duration).abs()));
    } else {
      sortedTracks = tracks;
    }

    for (final track in sortedTracks) {
      if (count > 4) break;

      final durationDiff = ((track.duration ?? 0) - duration).abs();

      if (track.syncedLyrics != null && durationDiff <= 5) {
        count++;
        callback(track.syncedLyrics!);
      }
      if (track.plainLyrics != null && durationDiff <= 5 && plain == 0) {
        count++;
        plain++;
        callback(track.plainLyrics!);
      }
    }
  }

  /// Get lyrics as a Result (success/failure)
  ///
  /// Returns a map with 'success' bool and either 'lyrics' or 'error'.
  Future<Map<String, dynamic>> getLyricsResult({
    required String videoId,
    int duration = 0,
  }) async {
    try {
      final lyrics = await getLyrics(videoId: videoId, duration: duration);
      return {'success': true, 'lyrics': lyrics};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Close the HTTP client
  void close() {
    _client.close();
  }
}

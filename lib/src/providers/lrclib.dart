import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lrclib_track.dart';
import '../models/parsed_lyrics.dart';
import '../utils/string_utils.dart';

/// LrcLib lyrics provider.
///
/// Fetches lyrics from https://lrclib.net API with multiple search strategies
/// for improved matching accuracy.
class LrcLib {
  static const String _baseUrl = 'https://lrclib.net';

  final http.Client _client;

  /// Create a new LrcLib instance
  LrcLib({http.Client? client}) : _client = client ?? http.Client();

  /// Query lyrics with specific parameters
  Future<List<LrcLibTrack>> _queryLyricsWithParams({
    String? trackName,
    String? artistName,
    String? albumName,
    String? query,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (query != null) queryParams['q'] = query;
      if (trackName != null) queryParams['track_name'] = trackName;
      if (artistName != null) queryParams['artist_name'] = artistName;
      if (albumName != null) queryParams['album_name'] = albumName;

      final uri = Uri.parse('$_baseUrl/api/search')
          .replace(queryParameters: queryParams);

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((json) => LrcLibTrack.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Query lyrics using multiple search strategies
  Future<List<LrcLibTrack>> queryLyrics(
    String artist,
    String title, {
    String? album,
  }) async {
    final cleanedTitle = cleanTitle(title);
    final cleanedArtist = cleanArtist(artist);

    // Strategy 1: Search with cleaned title and artist
    var results = await _queryLyricsWithParams(
      trackName: cleanedTitle,
      artistName: cleanedArtist,
      albumName: album,
    );
    results = results.where((t) => t.hasLyrics).toList();
    if (results.isNotEmpty) return results;

    // Strategy 2: Search with cleaned title only (artist might be different)
    results = await _queryLyricsWithParams(trackName: cleanedTitle);
    results = results.where((t) => t.hasLyrics).toList();
    if (results.isNotEmpty) return results;

    // Strategy 3: Use q parameter with combined search
    results = await _queryLyricsWithParams(
      query: '$cleanedArtist $cleanedTitle',
    );
    results = results.where((t) => t.hasLyrics).toList();
    if (results.isNotEmpty) return results;

    // Strategy 4: Use q parameter with just title
    results = await _queryLyricsWithParams(query: cleanedTitle);
    results = results.where((t) => t.hasLyrics).toList();
    if (results.isNotEmpty) return results;

    // Strategy 5: Try original title if different from cleaned
    if (cleanedTitle != title.trim()) {
      results = await _queryLyricsWithParams(
        trackName: title.trim(),
        artistName: artist.trim(),
      );
      results = results.where((t) => t.hasLyrics).toList();
    }

    return results;
  }

  /// Get lyrics for a track
  ///
  /// Returns the best matching lyrics text or throws an exception if unavailable.
  ///
  /// Parameters:
  /// - [title]: Track title
  /// - [artist]: Artist name
  /// - [duration]: Track duration in seconds (-1 to ignore duration matching)
  /// - [album]: Optional album name
  Future<String> getLyrics({
    required String title,
    required String artist,
    required int duration,
    String? album,
  }) async {
    final tracks = await queryLyrics(artist, title, album: album);
    final cleanedTitle = cleanTitle(title);
    final cleanedArtist = cleanArtist(artist);

    String? result;

    if (duration == -1) {
      final track =
          tracks.bestMatchingForWithNames(duration, cleanedTitle, cleanedArtist);
      result = track?.bestLyrics;
    } else {
      // Try with relaxed duration matching (±5 seconds instead of ±2)
      final track = tracks.bestMatchingForRelaxed(duration);
      result = track?.bestLyrics;
    }

    if (result != null) {
      return result;
    } else {
      throw Exception('Lyrics unavailable');
    }
  }

  /// Get all matching lyrics with callback
  ///
  /// Calls the callback for each matching lyrics found (up to 5).
  ///
  /// Parameters:
  /// - [title]: Track title
  /// - [artist]: Artist name
  /// - [duration]: Track duration in seconds (-1 to ignore duration matching)
  /// - [album]: Optional album name
  /// - [callback]: Function called for each lyrics found
  Future<void> getAllLyrics({
    required String title,
    required String artist,
    required int duration,
    String? album,
    required void Function(String lyrics) callback,
  }) async {
    final tracks = await queryLyrics(artist, title, album: album);
    final cleanedTitle = cleanTitle(title);
    final cleanedArtist = cleanArtist(artist);

    var count = 0;
    var plain = 0;

    List<LrcLibTrack> sortedTracks;

    if (duration == -1) {
      // Sort by similarity when no duration provided
      sortedTracks = List<LrcLibTrack>.from(tracks)
        ..sort((a, b) {
          var scoreA = 0.0;
          var scoreB = 0.0;

          if (a.syncedLyrics != null) scoreA += 1.0;
          if (b.syncedLyrics != null) scoreB += 1.0;

          final titleSimA =
              calculateStringSimilarity(cleanedTitle, a.trackName);
          final artistSimA =
              calculateStringSimilarity(cleanedArtist, a.artistName);
          scoreA += (titleSimA + artistSimA) / 2.0;

          final titleSimB =
              calculateStringSimilarity(cleanedTitle, b.trackName);
          final artistSimB =
              calculateStringSimilarity(cleanedArtist, b.artistName);
          scoreB += (titleSimB + artistSimB) / 2.0;

          return scoreB.compareTo(scoreA); // Descending
        });
    } else {
      // Sort by duration difference
      sortedTracks = List<LrcLibTrack>.from(tracks)
        ..sort((a, b) => (a.duration.toInt() - duration)
            .abs()
            .compareTo((b.duration.toInt() - duration).abs()));
    }

    for (final track in sortedTracks) {
      if (count > 4) break;

      if (track.syncedLyrics != null && duration == -1) {
        count++;
        callback(track.syncedLyrics!);
      } else {
        // Relaxed duration matching (±5 seconds)
        if (track.syncedLyrics != null &&
            (track.duration.toInt() - duration).abs() <= 5) {
          count++;
          callback(track.syncedLyrics!);
        }
        if (track.plainLyrics != null &&
            (track.duration.toInt() - duration).abs() <= 5 &&
            plain == 0) {
          count++;
          plain++;
          callback(track.plainLyrics!);
        }
      }
    }
  }

  /// Get lyrics as a Result (success/failure)
  ///
  /// Returns a map with 'success' bool and either 'lyrics' or 'error'.
  Future<Map<String, dynamic>> getLyricsResult({
    required String title,
    required String artist,
    required int duration,
    String? album,
  }) async {
    try {
      final lyrics = await getLyrics(
        title: title,
        artist: artist,
        duration: duration,
        album: album,
      );
      return {'success': true, 'lyrics': lyrics};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Simple lyrics query
  ///
  /// Returns list of matching tracks without duration filtering.
  Future<List<LrcLibTrack>> lyrics({
    required String artist,
    required String title,
  }) async {
    try {
      return await queryLyrics(artist, title);
    } catch (_) {
      return [];
    }
  }

  /// Parse LRC text into sentences map
  ///
  /// Returns a map of timestamp (in milliseconds) to text.
  static Map<int, String>? parseLyrics(String lrcText) {
    return ParsedLyrics.parseSentencesFromLrc(lrcText);
  }

  /// Create a LrcLibLyrics wrapper from text
  ///
  /// Equivalent to Kotlin's Lyrics inline value class.
  static LrcLibLyrics createLyrics(String text) {
    return LrcLibLyrics(text);
  }

  /// Get lyrics wrapped in LrcLibLyrics class (Kotlin-equivalent API)
  ///
  /// Returns LrcLibLyrics wrapper or throws exception if unavailable.
  Future<LrcLibLyrics> getLyricsWrapped({
    required String title,
    required String artist,
    required int duration,
    String? album,
  }) async {
    final text = await getLyrics(
      title: title,
      artist: artist,
      duration: duration,
      album: album,
    );
    return LrcLibLyrics(text);
  }

  /// Close the HTTP client
  void close() {
    _client.close();
  }
}

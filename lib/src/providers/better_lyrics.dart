import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/better_lyrics_response.dart';
import '../models/parsed_lyrics.dart';
import '../utils/ttml_parser.dart';

/// BetterLyrics provider.
///
/// Fetches lyrics from https://lyrics-api.boidu.dev API with TTML support
/// for word-level synced lyrics.
class BetterLyrics {
  static const String _baseUrl = 'https://lyrics-api.boidu.dev';

  final http.Client _client;

  /// Create a new BetterLyrics instance
  BetterLyrics({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch TTML lyrics from the API
  Future<String?> _fetchTTML({
    required String artist,
    required String title,
    int duration = -1,
    String? album,
  }) async {
    try {
      final queryParams = <String, String>{
        's': title,
        'a': artist,
      };

      if (duration > 0) {
        queryParams['d'] = duration.toString();
      }
      if (album != null && album.isNotEmpty) {
        queryParams['al'] = album;
      }

      final uri =
          Uri.parse('$_baseUrl/getLyrics').replace(queryParameters: queryParams);

      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final ttmlResponse = TTMLResponse.fromJson(json);
        return ttmlResponse.ttml.isNotEmpty ? ttmlResponse.ttml : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get lyrics for a track
  ///
  /// Returns LRC format lyrics text or throws an exception if unavailable.
  /// Uses exact title and artist without normalization to ensure correct sync.
  ///
  /// Parameters:
  /// - [title]: Track title
  /// - [artist]: Artist name
  /// - [duration]: Track duration in seconds
  /// - [album]: Optional album name
  Future<String> getLyrics({
    required String title,
    required String artist,
    required int duration,
    String? album,
  }) async {
    // Use exact title and artist - no normalization to ensure correct sync
    // Normalizing can return wrong lyrics (e.g., radio edit vs original)
    final ttml = await _fetchTTML(
      artist: artist,
      title: title,
      duration: duration,
      album: album,
    );

    if (ttml == null) {
      throw Exception('Lyrics unavailable');
    }

    final parsedLines = TTMLParser.parseTTML(ttml);
    if (parsedLines.isEmpty) {
      throw Exception('Failed to parse lyrics');
    }

    return TTMLParser.toLRC(parsedLines);
  }

  /// Get parsed lyrics with word-level timing
  ///
  /// Returns structured ParsedLyrics with line and word timing information.
  Future<ParsedLyrics> getParsedLyrics({
    required String title,
    required String artist,
    required int duration,
    String? album,
  }) async {
    final ttml = await _fetchTTML(
      artist: artist,
      title: title,
      duration: duration,
      album: album,
    );

    if (ttml == null) {
      throw Exception('Lyrics unavailable');
    }

    final parsedLines = TTMLParser.parseTTML(ttml);
    if (parsedLines.isEmpty) {
      throw Exception('Failed to parse lyrics');
    }

    return ParsedLyrics(
      text: TTMLParser.toLRC(parsedLines),
      lines: parsedLines,
      isSynced: true,
    );
  }

  /// Get raw TTML content
  ///
  /// Returns the raw TTML XML string for custom parsing.
  Future<String?> getRawTTML({
    required String title,
    required String artist,
    required int duration,
    String? album,
  }) async {
    return await _fetchTTML(
      artist: artist,
      title: title,
      duration: duration,
      album: album,
    );
  }

  /// Get all lyrics with callback
  ///
  /// Calls the callback with the lyrics if found.
  ///
  /// Parameters:
  /// - [title]: Track title
  /// - [artist]: Artist name
  /// - [duration]: Track duration in seconds
  /// - [album]: Optional album name
  /// - [callback]: Function called with lyrics if found
  Future<void> getAllLyrics({
    required String title,
    required String artist,
    required int duration,
    String? album,
    required void Function(String lyrics) callback,
  }) async {
    try {
      final lyrics = await getLyrics(
        title: title,
        artist: artist,
        duration: duration,
        album: album,
      );
      callback(lyrics);
    } catch (_) {
      // No lyrics available
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

  /// Close the HTTP client
  void close() {
    _client.close();
  }
}

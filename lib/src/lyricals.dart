import 'package:http/http.dart' as http;

import 'models/lrclib_track.dart';
import 'models/parsed_lyrics.dart';
import 'models/simpmusic_response.dart';
import 'providers/better_lyrics.dart';
import 'providers/lrclib.dart';
import 'providers/simpmusic.dart';
import 'utils/lrc_parser.dart';

export 'models/lrclib_track.dart' show LrcLibLyrics;

/// Lyrics source provider enum
enum LyricsSource {
  /// LrcLib.net - search by title/artist
  lrcLib,

  /// SimpMusic API - search by YouTube video ID
  simpMusic,

  /// BetterLyrics API - TTML with word-level sync
  betterLyrics,

  /// Try all sources in order
  all,
}

/// Unified lyrics provider that combines all three sources.
///
/// This class provides a single interface to fetch lyrics from:
/// - LrcLib (https://lrclib.net) - Traditional lyrics search by title/artist
/// - SimpMusic (https://api-lyrics.simpmusic.org) - YouTube video ID based
/// - BetterLyrics (https://lyrics-api.boidu.dev) - TTML with word-level timing
class Lyricals {
  final LrcLib _lrcLib;
  final SimpMusicLyrics _simpMusic;
  final BetterLyrics _betterLyrics;

  /// Create a new Lyricals instance
  ///
  /// Optionally provide a custom HTTP client for all providers.
  Lyricals({http.Client? client})
      : _lrcLib = LrcLib(client: client),
        _simpMusic = SimpMusicLyrics(client: client),
        _betterLyrics = BetterLyrics(client: client);

  /// Get the LrcLib provider instance
  LrcLib get lrcLib => _lrcLib;

  /// Get the SimpMusic provider instance
  SimpMusicLyrics get simpMusic => _simpMusic;

  /// Get the BetterLyrics provider instance
  BetterLyrics get betterLyrics => _betterLyrics;

  /// Get lyrics by title and artist
  ///
  /// Tries all sources in order: BetterLyrics -> LrcLib -> fails
  ///
  /// Parameters:
  /// - [title]: Track title
  /// - [artist]: Artist name
  /// - [duration]: Track duration in seconds (-1 to ignore)
  /// - [album]: Optional album name
  /// - [source]: Preferred source (defaults to trying all)
  Future<String> getLyrics({
    required String title,
    required String artist,
    int duration = -1,
    String? album,
    LyricsSource source = LyricsSource.all,
  }) async {
    switch (source) {
      case LyricsSource.lrcLib:
        return await _lrcLib.getLyrics(
          title: title,
          artist: artist,
          duration: duration,
          album: album,
        );

      case LyricsSource.betterLyrics:
        return await _betterLyrics.getLyrics(
          title: title,
          artist: artist,
          duration: duration,
          album: album,
        );

      case LyricsSource.simpMusic:
        throw Exception(
          'SimpMusic requires a video ID. Use getLyricsByVideoId instead.',
        );

      case LyricsSource.all:
        // Try BetterLyrics first (word-level sync)
        try {
          return await _betterLyrics.getLyrics(
            title: title,
            artist: artist,
            duration: duration,
            album: album,
          );
        } catch (_) {}

        // Fall back to LrcLib
        try {
          return await _lrcLib.getLyrics(
            title: title,
            artist: artist,
            duration: duration,
            album: album,
          );
        } catch (_) {}

        throw Exception('Lyrics unavailable from all sources');
    }
  }

  /// Get lyrics by YouTube video ID (SimpMusic only)
  ///
  /// Parameters:
  /// - [videoId]: YouTube video ID
  /// - [duration]: Optional track duration in seconds for better matching
  Future<String> getLyricsByVideoId({
    required String videoId,
    int duration = 0,
  }) async {
    return await _simpMusic.getLyrics(
      videoId: videoId,
      duration: duration,
    );
  }

  /// Get lyrics with source preference and fallback
  ///
  /// Returns a map with 'source', 'success', and 'lyrics' or 'error'.
  Future<Map<String, dynamic>> getLyricsWithSource({
    required String title,
    required String artist,
    int duration = -1,
    String? album,
    String? videoId,
  }) async {
    // Try BetterLyrics first (word-level sync)
    try {
      final lyrics = await _betterLyrics.getLyrics(
        title: title,
        artist: artist,
        duration: duration,
        album: album,
      );
      return {
        'success': true,
        'source': 'betterLyrics',
        'lyrics': lyrics,
      };
    } catch (_) {}

    // Try SimpMusic if video ID is provided
    if (videoId != null && videoId.isNotEmpty) {
      try {
        final lyrics = await _simpMusic.getLyrics(
          videoId: videoId,
          duration: duration,
        );
        return {
          'success': true,
          'source': 'simpMusic',
          'lyrics': lyrics,
        };
      } catch (_) {}
    }

    // Fall back to LrcLib
    try {
      final lyrics = await _lrcLib.getLyrics(
        title: title,
        artist: artist,
        duration: duration,
        album: album,
      );
      return {
        'success': true,
        'source': 'lrcLib',
        'lyrics': lyrics,
      };
    } catch (_) {}

    return {
      'success': false,
      'error': 'Lyrics unavailable from all sources',
    };
  }

  /// Get all matching lyrics from all sources with callback
  ///
  /// Calls the callback for each unique lyrics found from all sources.
  Future<void> getAllLyrics({
    required String title,
    required String artist,
    int duration = -1,
    String? album,
    String? videoId,
    required void Function(String lyrics, String source) callback,
  }) async {
    final seenLyrics = <String>{};

    void addIfNew(String lyrics, String source) {
      // Use first 100 chars as a simple dedup key
      final key = lyrics.length > 100 ? lyrics.substring(0, 100) : lyrics;
      if (!seenLyrics.contains(key)) {
        seenLyrics.add(key);
        callback(lyrics, source);
      }
    }

    // BetterLyrics
    await _betterLyrics.getAllLyrics(
      title: title,
      artist: artist,
      duration: duration,
      album: album,
      callback: (lyrics) => addIfNew(lyrics, 'betterLyrics'),
    );

    // SimpMusic (if video ID provided)
    if (videoId != null && videoId.isNotEmpty) {
      await _simpMusic.getAllLyrics(
        videoId: videoId,
        duration: duration,
        callback: (lyrics) => addIfNew(lyrics, 'simpMusic'),
      );
    }

    // LrcLib
    await _lrcLib.getAllLyrics(
      title: title,
      artist: artist,
      duration: duration,
      album: album,
      callback: (lyrics) => addIfNew(lyrics, 'lrcLib'),
    );
  }

  /// Search for tracks on LrcLib
  ///
  /// Returns a list of matching tracks.
  Future<List<LrcLibTrack>> searchTracks({
    required String artist,
    required String title,
  }) async {
    return await _lrcLib.lyrics(artist: artist, title: title);
  }

  /// Get lyrics data from SimpMusic by video ID
  ///
  /// Returns detailed lyrics data including metadata.
  Future<List<SimpMusicLyricsData>> getLyricsDataByVideoId(
      String videoId) async {
    return await _simpMusic.getLyricsByVideoId(videoId);
  }

  /// Get parsed lyrics with word-level timing from BetterLyrics
  ///
  /// Returns structured ParsedLyrics with line and word timing information.
  Future<ParsedLyrics> getParsedLyrics({
    required String title,
    required String artist,
    required int duration,
    String? album,
  }) async {
    return await _betterLyrics.getParsedLyrics(
      title: title,
      artist: artist,
      duration: duration,
      album: album,
    );
  }

  /// Get raw TTML content from BetterLyrics
  ///
  /// Returns the raw TTML XML string for custom parsing.
  Future<String?> getRawTTML({
    required String title,
    required String artist,
    required int duration,
    String? album,
  }) async {
    return await _betterLyrics.getRawTTML(
      title: title,
      artist: artist,
      duration: duration,
      album: album,
    );
  }

  /// Parse LRC text into sentences map
  ///
  /// Returns a map of timestamp (in milliseconds) to text.
  static Map<int, String>? parseLyrics(String lrcText) {
    return LrcParser.getSentences(lrcText);
  }

  /// Parse LRC text using Kotlin-style character position parsing
  ///
  /// Returns a map of timestamp (in milliseconds) to text.
  static Map<int, String>? parseLyricsKotlinStyle(String lrcText) {
    return LrcParser.parseSentencesKotlinStyle(lrcText);
  }

  /// Parse LRC text into structured ParsedLyrics
  static ParsedLyrics parseLrcText(String lrcText) {
    return LrcParser.parse(lrcText);
  }

  /// Create a LrcLibLyrics wrapper from text
  ///
  /// Equivalent to Kotlin's Lyrics inline value class.
  /// Use `.sentences` to get the timestamp -> text map.
  static LrcLibLyrics createLyrics(String text) {
    return LrcLibLyrics(text);
  }

  /// Get lyrics wrapped in LrcLibLyrics class (Kotlin-equivalent API)
  ///
  /// Returns LrcLibLyrics wrapper with `.sentences` getter.
  Future<LrcLibLyrics> getLyricsWrapped({
    required String title,
    required String artist,
    required int duration,
    String? album,
    LyricsSource source = LyricsSource.all,
  }) async {
    final text = await getLyrics(
      title: title,
      artist: artist,
      duration: duration,
      album: album,
      source: source,
    );
    return LrcLibLyrics(text);
  }

  /// Close all HTTP clients
  void close() {
    _lrcLib.close();
    _simpMusic.close();
    _betterLyrics.close();
  }
}

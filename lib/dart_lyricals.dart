/// A comprehensive Dart package for fetching lyrics from multiple sources.
///
/// This package provides a unified API for fetching lyrics from:
/// - LrcLib (https://lrclib.net)
/// - SimpMusic API (https://api-lyrics.simpmusic.org)
/// - BetterLyrics API (https://lyrics-api.boidu.dev)
library dart_lyricals;

// Models
export 'src/models/lrclib_track.dart';
export 'src/models/simpmusic_response.dart';
export 'src/models/better_lyrics_response.dart'
    hide BetterLyrics; // Hide model class, provider class is exported below
export 'src/models/parsed_lyrics.dart';

// Providers
export 'src/providers/lrclib.dart';
export 'src/providers/simpmusic.dart';
export 'src/providers/better_lyrics.dart'; // BetterLyrics provider class

// Utils
export 'src/utils/string_utils.dart';
export 'src/utils/ttml_parser.dart';
export 'src/utils/lrc_parser.dart';

// Main unified class
export 'src/lyricals.dart';

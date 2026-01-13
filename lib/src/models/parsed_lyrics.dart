/// Represents parsed lyrics with optional word-level timing.
class ParsedLyrics {
  final String text;
  final List<ParsedLine> lines;
  final bool isSynced;

  const ParsedLyrics({
    required this.text,
    this.lines = const [],
    this.isSynced = false,
  });

  /// Get sentences map (timestamp in ms -> text)
  Map<int, String>? get sentences {
    if (!isSynced || lines.isEmpty) return null;

    try {
      final result = <int, String>{0: ''};
      for (final line in lines) {
        final timeMs = (line.startTime * 1000).toInt();
        result[timeMs] = line.text;
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Parse sentences from raw LRC text using Kotlin-style character positions
  /// Format: [mm:ss.xx]text where positions are:
  /// Index:  0123456789...
  ///         [01:23.45]text
  static Map<int, String>? parseSentencesFromLrc(String lrcText) {
    try {
      final result = <int, String>{0: ''};
      final lines = lrcText.trim().split('\n');

      for (final line in lines) {
        if (line.length < 10) continue;

        // Parse using character positions like Kotlin version
        // Format: [00:00.00]text
        // Index:   01234567890
        try {
          // Validate format before parsing
          if (line[0] != '[' || line[3] != ':' || line[6] != '.' || line[9] != ']') {
            continue;
          }

          final timeMs = _digitToInt(line[8]) * 10 +
              _digitToInt(line[7]) * 100 +
              _digitToInt(line[5]) * 1000 +
              _digitToInt(line[4]) * 10000 +
              _digitToInt(line[2]) * 60 * 1000 +
              _digitToInt(line[1]) * 600 * 1000;

          result[timeMs] = line.substring(10);
        } catch (_) {
          // Skip malformed lines
        }
      }
      return result.length > 1 ? result : null;
    } catch (_) {
      return null;
    }
  }

  /// Convert character to integer (like Kotlin's digitToInt)
  static int _digitToInt(String char) {
    final code = char.codeUnitAt(0);
    if (code >= 48 && code <= 57) {
      return code - 48;
    }
    throw FormatException('Not a digit: $char');
  }

  @override
  String toString() =>
      'ParsedLyrics(lines: ${lines.length}, isSynced: $isSynced)';
}

/// A parsed line with timing information.
class ParsedLine {
  final String text;
  final double startTime;
  final List<ParsedWord> words;

  const ParsedLine({
    required this.text,
    required this.startTime,
    this.words = const [],
  });

  @override
  String toString() => 'ParsedLine(text: $text, startTime: $startTime)';
}

/// A parsed word with timing information.
class ParsedWord {
  final String text;
  final double startTime;
  final double endTime;

  const ParsedWord({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  @override
  String toString() =>
      'ParsedWord(text: $text, startTime: $startTime, endTime: $endTime)';
}

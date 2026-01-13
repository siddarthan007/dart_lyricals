import '../models/parsed_lyrics.dart';

/// Parser for LRC (Lyric) format files.
class LrcParser {
  /// Parse LRC text into structured lyrics
  static ParsedLyrics parse(String lrcText) {
    final lines = <ParsedLine>[];
    final rawLines = lrcText.trim().split('\n');

    // Check if it's synced (has timestamps)
    final isSynced = rawLines.any((line) =>
        RegExp(r'^\[\d{2}:\d{2}\.\d{2,3}\]').hasMatch(line));

    for (final line in rawLines) {
      if (line.length < 10) continue;

      // Parse [mm:ss.xx] format
      final match =
          RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)').firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final msStr = match.group(3)!;
        final milliseconds = int.parse(msStr.padRight(3, '0'));
        final text = match.group(4) ?? '';

        final startTime =
            minutes * 60.0 + seconds + milliseconds / 1000.0;

        lines.add(ParsedLine(
          text: text,
          startTime: startTime,
          words: [],
        ));
      }
    }

    return ParsedLyrics(
      text: lrcText,
      lines: lines,
      isSynced: isSynced,
    );
  }

  /// Get sentences map from LRC text (timestamp in ms -> text)
  static Map<int, String>? getSentences(String lrcText) {
    try {
      final result = <int, String>{0: ''};
      final lines = lrcText.trim().split('\n');

      for (final line in lines) {
        if (line.length < 10) continue;

        // Parse [mm:ss.xx] format - handle both 2 and 3 digit centiseconds
        final match =
            RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)').firstMatch(line);
        if (match != null) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final msStr = match.group(3)!;

          // Handle both [mm:ss.xx] and [mm:ss.xxx] formats
          int milliseconds;
          if (msStr.length == 2) {
            milliseconds = int.parse(msStr) * 10; // centiseconds to ms
          } else {
            milliseconds = int.parse(msStr);
          }

          final text = match.group(4) ?? '';
          final timeMs = minutes * 60000 + seconds * 1000 + milliseconds;
          result[timeMs] = text;
        }
      }
      return result.length > 1 ? result : null;
    } catch (_) {
      return null;
    }
  }

  /// Parse sentences from LRC using original Kotlin logic
  /// Format: [mm:ss.xx]text
  /// Returns map of milliseconds -> text
  static Map<int, String>? parseSentencesKotlinStyle(String lrcText) {
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
          if (line[0] != '[' ||
              line[3] != ':' ||
              line[6] != '.' ||
              line[9] != ']') {
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

  /// Convert structured lyrics to LRC format
  static String toLrc(List<ParsedLine> lines) {
    final buffer = StringBuffer();

    for (final line in lines) {
      final timeMs = (line.startTime * 1000).toInt();
      final minutes = timeMs ~/ 60000;
      final seconds = (timeMs % 60000) ~/ 1000;
      final centiseconds = (timeMs % 1000) ~/ 10;

      final timestamp = '[${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${centiseconds.toString().padLeft(2, '0')}]';

      buffer.writeln('$timestamp${line.text}');
    }

    return buffer.toString();
  }
}

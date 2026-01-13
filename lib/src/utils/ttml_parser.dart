import 'package:xml/xml.dart';

import '../models/parsed_lyrics.dart';

/// Parser for TTML (Timed Text Markup Language) lyrics format.
class TTMLParser {
  /// Parse TTML content into structured lines
  static List<ParsedLine> parseTTML(String ttml) {
    final lines = <ParsedLine>[];

    try {
      final document = XmlDocument.parse(ttml);
      final pElements = document.findAllElements('p');

      for (final pElement in pElements) {
        final begin = pElement.getAttribute('begin');
        if (begin == null || begin.isEmpty) continue;

        final startTime = parseTime(begin);
        final spanInfos = <_SpanInfo>[];

        // Parse child nodes to preserve whitespace between spans
        final childNodes = pElement.children;
        for (var i = 0; i < childNodes.length; i++) {
          final node = childNodes[i];

          if (node is XmlElement && node.name.local.toLowerCase() == 'span') {
            final wordBegin = node.getAttribute('begin');
            final wordEnd = node.getAttribute('end');
            final wordText = node.innerText;

            if (wordText.isNotEmpty &&
                wordBegin != null &&
                wordBegin.isNotEmpty &&
                wordEnd != null &&
                wordEnd.isNotEmpty) {
              // Check if next sibling is whitespace text node
              final nextIndex = i + 1;
              var hasTrailingSpace = false;
              if (nextIndex < childNodes.length) {
                final nextSibling = childNodes[nextIndex];
                if (nextSibling is XmlText) {
                  hasTrailingSpace =
                      RegExp(r'\s').hasMatch(nextSibling.value);
                }
              }

              spanInfos.add(_SpanInfo(
                text: wordText,
                startTime: parseTime(wordBegin),
                endTime: parseTime(wordEnd),
                hasTrailingSpace: hasTrailingSpace,
              ));
            }
          }
        }

        // Merge consecutive spans without whitespace between them into single words
        final words = _mergeSpansIntoWords(spanInfos);
        final lineText = words.map((w) => w.text).join(' ');

        // If no spans found, use text content directly
        final finalText =
            lineText.isEmpty ? pElement.innerText.trim() : lineText;

        if (finalText.isNotEmpty) {
          lines.add(ParsedLine(
            text: finalText,
            startTime: startTime,
            words: words,
          ));
        }
      }
    } catch (_) {
      return [];
    }

    return lines;
  }

  /// Convert parsed lines to LRC format string
  static String toLRC(List<ParsedLine> lines) {
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

      // Add word timing data if available
      if (line.words.isNotEmpty) {
        final wordsData = line.words
            .map((word) => '${word.text}:${word.startTime}:${word.endTime}')
            .join('|');
        buffer.writeln('<$wordsData>');
      }
    }

    return buffer.toString();
  }

  /// Merge spans into words based on whitespace boundaries
  static List<ParsedWord> _mergeSpansIntoWords(List<_SpanInfo> spanInfos) {
    if (spanInfos.isEmpty) return [];

    final words = <ParsedWord>[];
    var currentText = StringBuffer();
    var currentStartTime = spanInfos[0].startTime;
    var currentEndTime = spanInfos[0].endTime;

    for (var index = 0; index < spanInfos.length; index++) {
      final span = spanInfos[index];

      if (index == 0) {
        currentText.write(span.text);
        currentStartTime = span.startTime;
        currentEndTime = span.endTime;
      } else {
        // Check if previous span had trailing space (word boundary)
        final prevSpan = spanInfos[index - 1];
        if (prevSpan.hasTrailingSpace) {
          // Save current word and start new one
          if (currentText.isNotEmpty) {
            words.add(ParsedWord(
              text: currentText.toString().trim(),
              startTime: currentStartTime,
              endTime: currentEndTime,
            ));
          }
          currentText = StringBuffer(span.text);
          currentStartTime = span.startTime;
          currentEndTime = span.endTime;
        } else {
          // No space between spans - merge into same word (syllables)
          currentText.write(span.text);
          currentEndTime = span.endTime;
        }
      }
    }

    // Add the last word
    if (currentText.isNotEmpty) {
      words.add(ParsedWord(
        text: currentText.toString().trim(),
        startTime: currentStartTime,
        endTime: currentEndTime,
      ));
    }

    return words;
  }

  /// Parse time string to seconds
  static double parseTime(String timeStr) {
    try {
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        switch (parts.length) {
          case 2:
            final minutes = double.parse(parts[0]);
            final seconds = double.parse(parts[1]);
            return minutes * 60 + seconds;
          case 3:
            final hours = double.parse(parts[0]);
            final minutes = double.parse(parts[1]);
            final seconds = double.parse(parts[2]);
            return hours * 3600 + minutes * 60 + seconds;
          default:
            return double.tryParse(timeStr) ?? 0.0;
        }
      } else {
        return double.tryParse(timeStr) ?? 0.0;
      }
    } catch (_) {
      return 0.0;
    }
  }
}

/// Internal helper class for span information
class _SpanInfo {
  final String text;
  final double startTime;
  final double endTime;
  final bool hasTrailingSpace;

  const _SpanInfo({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.hasTrailingSpace,
  });
}

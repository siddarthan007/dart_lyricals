# dart_lyricals

A Dart package for fetching lyrics from multiple sources with full Flutter support.

[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.0.0-blue.svg)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-green.svg)](https://flutter.dev)

## Sources

- **LrcLib** - Search by title/artist
- **SimpMusic** - Search by YouTube video ID
- **BetterLyrics** - Word-level synced lyrics (TTML)

## Installation

```yaml
dependencies:
  dart_lyricals:
    path: ../dart_lyricals
```

## Quick Start

```dart
import 'package:dart_lyricals/dart_lyricals.dart';

void main() async {
  final lyricals = Lyricals();

  // Get lyrics (tries all sources)
  final lyrics = await lyricals.getLyrics(
    title: 'Bohemian Rhapsody',
    artist: 'Queen',
    duration: 354,
  );
  print(lyrics);

  lyricals.close();
}
```

## Using Specific Providers

```dart
// LrcLib - by title/artist
final lrcLib = LrcLib();
final lyrics = await lrcLib.getLyrics(
  title: 'Yesterday',
  artist: 'The Beatles',
  duration: 125,
);

// SimpMusic - by YouTube video ID
final simpMusic = SimpMusicLyrics();
final lyrics = await simpMusic.getLyrics(
  videoId: 'dQw4w9WgXcQ',
  duration: 212,
);

// BetterLyrics - word-level sync
final betterLyrics = BetterLyrics();
final lyrics = await betterLyrics.getLyrics(
  title: 'Never Gonna Give You Up',
  artist: 'Rick Astley',
  duration: 212,
);
```

## Get Lyrics with Source Info

```dart
final result = await lyricals.getLyricsWithSource(
  title: 'Shape of You',
  artist: 'Ed Sheeran',
  duration: 234,
);

if (result['success']) {
  print('Source: ${result['source']}');
  print('Lyrics: ${result['lyrics']}');
}
```

## Word-Level Timing

```dart
final parsed = await lyricals.getParsedLyrics(
  title: 'Song Title',
  artist: 'Artist Name',
  duration: 200,
);

for (final line in parsed.lines) {
  print('Line: ${line.text}');
  for (final word in line.words) {
    print('  ${word.text} (${word.startTime} - ${word.endTime})');
  }
}
```

## Parse LRC Text

```dart
// Parse to timestamp -> text map
final sentences = Lyricals.parseLyrics(lrcText);
sentences?.forEach((timeMs, text) {
  print('[$timeMs] $text');
});

// Parse to structured format
final parsed = Lyricals.parseLrcText(lrcText);
for (final line in parsed.lines) {
  print('[${line.startTime}] ${line.text}');
}
```

## Flutter Usage

```dart
import 'package:flutter/material.dart';
import 'package:dart_lyricals/dart_lyricals.dart';

class LyricsService {
  final Lyricals _lyricals = Lyricals();

  Future<String?> fetchLyrics({
    required String title,
    required String artist,
    int duration = -1,
  }) async {
    try {
      return await _lyricals.getLyrics(
        title: title,
        artist: artist,
        duration: duration,
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _lyricals.close();
  }
}

// In your widget
class LyricsScreen extends StatefulWidget {
  final String title;
  final String artist;

  const LyricsScreen({required this.title, required this.artist});

  @override
  _LyricsScreenState createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final _lyricsService = LyricsService();
  String? _lyrics;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    final lyrics = await _lyricsService.fetchLyrics(
      title: widget.title,
      artist: widget.artist,
    );
    setState(() => _lyrics = lyrics);
  }

  @override
  void dispose() {
    _lyricsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Text(_lyrics ?? 'Loading...'),
    );
  }
}
```

## API Overview

| Method | Description |
|--------|-------------|
| `getLyrics()` | Get lyrics by title/artist |
| `getLyricsByVideoId()` | Get lyrics by YouTube video ID |
| `getLyricsWithSource()` | Get lyrics with source info |
| `getAllLyrics()` | Get all matches with callback |
| `getParsedLyrics()` | Get word-level synced lyrics |
| `searchTracks()` | Search tracks on LrcLib |
| `parseLyrics()` | Parse LRC to timestamp map |
| `parseLrcText()` | Parse LRC to structured format |

## Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## License

MIT License

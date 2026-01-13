/// TTML response from BetterLyrics API.
class TTMLResponse {
  final String ttml;

  const TTMLResponse({required this.ttml});

  factory TTMLResponse.fromJson(Map<String, dynamic> json) {
    return TTMLResponse(
      ttml: json['ttml'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'ttml': ttml};

  @override
  String toString() => 'TTMLResponse(ttml: ${ttml.length} chars)';
}

/// Search response from BetterLyrics API.
class BetterLyricsSearchResponse {
  final List<BetterLyricsTrack> results;

  const BetterLyricsSearchResponse({this.results = const []});

  factory BetterLyricsSearchResponse.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List<dynamic>?;
    return BetterLyricsSearchResponse(
      results: resultsList
              ?.map((e) =>
                  BetterLyricsTrack.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'BetterLyricsSearchResponse(results: ${results.length} items)';
}

/// Track model for BetterLyrics API.
class BetterLyricsTrack {
  final String title;
  final String artist;
  final String? album;
  final double duration;
  final BetterLyrics? lyrics;

  const BetterLyricsTrack({
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    this.lyrics,
  });

  factory BetterLyricsTrack.fromJson(Map<String, dynamic> json) {
    return BetterLyricsTrack(
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String?,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      lyrics: json['lyrics'] != null
          ? BetterLyrics.fromJson(json['lyrics'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'album': album,
        'duration': duration,
        'lyrics': lyrics?.toJson(),
      };

  @override
  String toString() =>
      'BetterLyricsTrack(title: $title, artist: $artist, duration: $duration)';
}

/// Lyrics model containing lines.
class BetterLyrics {
  final List<BetterLyricsLine> lines;

  const BetterLyrics({this.lines = const []});

  factory BetterLyrics.fromJson(Map<String, dynamic> json) {
    final linesList = json['lines'] as List<dynamic>?;
    return BetterLyrics(
      lines: linesList
              ?.map((e) =>
                  BetterLyricsLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'lines': lines.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() => 'BetterLyrics(lines: ${lines.length})';
}

/// A single line of lyrics.
class BetterLyricsLine {
  final String text;
  final double startTime;
  final List<BetterLyricsWord>? words;

  const BetterLyricsLine({
    required this.text,
    required this.startTime,
    this.words,
  });

  factory BetterLyricsLine.fromJson(Map<String, dynamic> json) {
    final wordsList = json['words'] as List<dynamic>?;
    return BetterLyricsLine(
      text: json['text'] as String? ?? '',
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      words: wordsList
          ?.map((e) => BetterLyricsWord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'startTime': startTime,
        'words': words?.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() => 'BetterLyricsLine(text: $text, startTime: $startTime)';
}

/// A single word within a lyrics line.
class BetterLyricsWord {
  final String text;
  final double startTime;
  final double endTime;

  const BetterLyricsWord({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory BetterLyricsWord.fromJson(Map<String, dynamic> json) {
    return BetterLyricsWord(
      text: json['text'] as String? ?? '',
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['endTime'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'startTime': startTime,
        'endTime': endTime,
      };

  @override
  String toString() =>
      'BetterLyricsWord(text: $text, startTime: $startTime, endTime: $endTime)';
}

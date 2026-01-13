/// Lyrics wrapper class equivalent to Kotlin's inline value class.
/// Provides convenient parsing of LRC format lyrics.
class LrcLibLyrics {
  final String text;

  const LrcLibLyrics(this.text);

  /// Get sentences map (timestamp in ms -> text)
  /// Uses exact Kotlin-style character position parsing.
  Map<int, String>? get sentences {
    try {
      final result = <int, String>{0: ''};
      final lines = text.trim().split('\n');

      for (final line in lines) {
        if (line.length < 10) continue;

        try {
          // Validate format: [mm:ss.xx]
          if (line[0] != '[' ||
              line[3] != ':' ||
              line[6] != '.' ||
              line[9] != ']') {
            continue;
          }

          // Parse using character positions like Kotlin version
          // Format: [00:00.00]text
          // Index:   01234567890
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
  String toString() => 'LrcLibLyrics(${text.length} chars)';
}

/// Track model for LrcLib API response.
class LrcLibTrack {
  final int id;
  final String trackName;
  final String artistName;
  final double duration;
  final String? plainLyrics;
  final String? syncedLyrics;

  const LrcLibTrack({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.duration,
    this.plainLyrics,
    this.syncedLyrics,
  });

  factory LrcLibTrack.fromJson(Map<String, dynamic> json) {
    return LrcLibTrack(
      id: json['id'] as int,
      trackName: json['trackName'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      plainLyrics: json['plainLyrics'] as String?,
      syncedLyrics: json['syncedLyrics'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trackName': trackName,
        'artistName': artistName,
        'duration': duration,
        'plainLyrics': plainLyrics,
        'syncedLyrics': syncedLyrics,
      };

  /// Check if track has any lyrics (synced or plain)
  bool get hasLyrics => syncedLyrics != null || plainLyrics != null;

  /// Get the best available lyrics (prefer synced)
  String? get bestLyrics => syncedLyrics ?? plainLyrics;

  @override
  String toString() =>
      'LrcLibTrack(id: $id, trackName: $trackName, artistName: $artistName, duration: $duration)';
}

/// Extension methods for List<LrcLibTrack> matching
extension LrcLibTrackListExtensions on List<LrcLibTrack> {
  /// Find best matching track for given duration with ±2 seconds tolerance
  LrcLibTrack? bestMatchingFor(int duration) {
    if (isEmpty) return null;

    if (duration == -1) {
      return firstWhere(
        (track) => track.syncedLyrics != null,
        orElse: () => first,
      );
    }

    final sorted = List<LrcLibTrack>.from(this)
      ..sort((a, b) =>
          (a.duration.toInt() - duration).abs().compareTo(
                (b.duration.toInt() - duration).abs(),
              ));

    final best = sorted.first;
    if ((best.duration.toInt() - duration).abs() <= 2) {
      return best;
    }
    return null;
  }

  /// Find best matching track with relaxed ±5 seconds tolerance
  LrcLibTrack? bestMatchingForRelaxed(int duration) {
    if (isEmpty) return null;

    if (duration == -1) {
      return firstWhere(
        (track) => track.syncedLyrics != null,
        orElse: () => first,
      );
    }

    // First try to find synced lyrics within tolerance
    final syncedTracks = where((t) => t.syncedLyrics != null).toList();
    if (syncedTracks.isNotEmpty) {
      syncedTracks.sort((a, b) =>
          (a.duration.toInt() - duration).abs().compareTo(
                (b.duration.toInt() - duration).abs(),
              ));
      final syncedMatch = syncedTracks.first;
      if ((syncedMatch.duration.toInt() - duration).abs() <= 5) {
        return syncedMatch;
      }
    }

    // Fall back to any lyrics within tolerance
    final sorted = List<LrcLibTrack>.from(this)
      ..sort((a, b) =>
          (a.duration.toInt() - duration).abs().compareTo(
                (b.duration.toInt() - duration).abs(),
              ));

    final best = sorted.first;
    if ((best.duration.toInt() - duration).abs() <= 5) {
      return best;
    }
    return null;
  }

  /// Find best match using string similarity for track and artist names
  LrcLibTrack? bestMatchingForWithNames(
    int duration,
    String? trackName,
    String? artistName,
  ) {
    if (isEmpty) return null;

    if (duration == -1) {
      if (trackName != null && artistName != null) {
        return _findBestMatch(trackName, artistName);
      }
      return firstWhere(
        (track) => track.syncedLyrics != null,
        orElse: () => first,
      );
    }

    return bestMatchingForRelaxed(duration);
  }

  LrcLibTrack? _findBestMatch(String trackName, String artistName) {
    final normalizedTrackName = trackName.trim().toLowerCase();
    final normalizedArtistName = artistName.trim().toLowerCase();

    LrcLibTrack? bestMatch;
    double bestScore = 0.0;

    for (final track in this) {
      final trackNameSimilarity = _calculateSimilarity(
        normalizedTrackName,
        track.trackName.trim().toLowerCase(),
      );
      final artistNameSimilarity = _calculateSimilarity(
        normalizedArtistName,
        track.artistName.trim().toLowerCase(),
      );

      var score = (trackNameSimilarity + artistNameSimilarity) / 2.0;
      if (track.syncedLyrics != null) score += 0.1;

      if (score > bestScore) {
        bestScore = score;
        bestMatch = track;
      }
    }

    // Only return if similarity is above threshold
    if (bestMatch != null) {
      final trackNameSimilarity = _calculateSimilarity(
        normalizedTrackName,
        bestMatch.trackName.trim().toLowerCase(),
      );
      final artistNameSimilarity = _calculateSimilarity(
        normalizedArtistName,
        bestMatch.artistName.trim().toLowerCase(),
      );
      if ((trackNameSimilarity + artistNameSimilarity) / 2.0 > 0.6) {
        return bestMatch;
      }
    }
    return null;
  }

  double _calculateSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    final containsScore =
        (str1.contains(str2) || str2.contains(str1)) ? 0.8 : 0.0;

    final maxLength = str1.length > str2.length ? str1.length : str2.length;
    final distance = _levenshteinDistance(str1, str2);
    final distanceScore = 1.0 - (distance / maxLength);

    return containsScore > distanceScore ? containsScore : distanceScore;
  }

  int _levenshteinDistance(String str1, String str2) {
    final len1 = str1.length;
    final len2 = str2.length;
    final matrix = List.generate(
      len1 + 1,
      (_) => List.filled(len2 + 1, 0),
    );

    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = str1[i - 1] == str2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }
}

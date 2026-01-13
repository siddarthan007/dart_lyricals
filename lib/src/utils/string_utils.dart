/// String utility functions for lyrics matching.
library;

/// Patterns to clean from title
final List<RegExp> titleCleanupPatterns = [
  RegExp(
    r'\s*\(.*?(official|video|audio|lyrics|lyric|visualizer|hd|hq|4k|remaster|remix|live|acoustic|version|edit|extended|radio|clean|explicit).*?\)',
    caseSensitive: false,
  ),
  RegExp(
    r'\s*\[.*?(official|video|audio|lyrics|lyric|visualizer|hd|hq|4k|remaster|remix|live|acoustic|version|edit|extended|radio|clean|explicit).*?\]',
    caseSensitive: false,
  ),
  RegExp(r'\s*【.*?】'),
  RegExp(r'\s*\|.*$'),
  RegExp(
    r'\s*-\s*(official|video|audio|lyrics|lyric|visualizer).*$',
    caseSensitive: false,
  ),
  RegExp(r'\s*\(feat\..*?\)', caseSensitive: false),
  RegExp(r'\s*\(ft\..*?\)', caseSensitive: false),
  RegExp(r'\s*feat\..*$', caseSensitive: false),
  RegExp(r'\s*ft\..*$', caseSensitive: false),
];

/// Separators used to extract primary artist
const List<String> artistSeparators = [
  ' & ',
  ' and ',
  ', ',
  ' x ',
  ' X ',
  ' feat. ',
  ' feat ',
  ' ft. ',
  ' ft ',
  ' featuring ',
  ' with ',
];

/// Clean title by removing common suffixes like (Official Video), etc.
String cleanTitle(String title) {
  var cleaned = title.trim();
  for (final pattern in titleCleanupPatterns) {
    cleaned = cleaned.replaceAll(pattern, '');
  }
  return cleaned.trim();
}

/// Clean artist by extracting primary artist name
String cleanArtist(String artist) {
  var cleaned = artist.trim();
  for (final separator in artistSeparators) {
    final index = cleaned.toLowerCase().indexOf(separator.toLowerCase());
    if (index != -1) {
      cleaned = cleaned.substring(0, index);
      break;
    }
  }
  return cleaned.trim();
}

/// Calculate string similarity using Levenshtein distance
double calculateStringSimilarity(String str1, String str2) {
  final s1 = str1.trim().toLowerCase();
  final s2 = str2.trim().toLowerCase();

  if (s1 == s2) return 1.0;
  if (s1.isEmpty || s2.isEmpty) return 0.0;

  if (s1.contains(s2) || s2.contains(s1)) {
    return 0.8;
  }

  final maxLength = s1.length > s2.length ? s1.length : s2.length;
  final distance = levenshteinDistance(s1, s2);
  return 1.0 - (distance / maxLength);
}

/// Calculate Levenshtein distance between two strings
int levenshteinDistance(String str1, String str2) {
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

import 'package:dart_lyricals/dart_lyricals.dart';

void main() async {
  // Create the unified lyrics client
  final lyricals = Lyricals();

  print('=== dart_lyricals Example ===\n');

  // Example 1: Get lyrics using the unified API (tries all sources)
  print('1. Getting lyrics with unified API...');
  try {
    final lyrics = await lyricals.getLyrics(
      title: 'Shape of You',
      artist: 'Ed Sheeran',
      duration: 234,
    );
    print('Found lyrics (${lyrics.length} chars)');
    print(
        'First 200 chars:\n${lyrics.substring(0, lyrics.length > 200 ? 200 : lyrics.length)}...\n');
  } catch (e) {
    print('Error: $e\n');
  }

  // Example 2: Get lyrics with source information
  print('2. Getting lyrics with source info...');
  final result = await lyricals.getLyricsWithSource(
    title: 'Bohemian Rhapsody',
    artist: 'Queen',
    duration: 354,
  );
  if (result['success'] == true) {
    print('Source: ${result['source']}');
    final lyrics = result['lyrics'] as String;
    print('Found lyrics (${lyrics.length} chars)\n');
  } else {
    print('Error: ${result['error']}\n');
  }

  // Example 3: Use LrcLib directly
  print('3. Using LrcLib directly...');
  final lrcLib = lyricals.lrcLib;
  try {
    final tracks = await lrcLib.lyrics(
      artist: 'The Beatles',
      title: 'Yesterday',
    );
    print('Found ${tracks.length} tracks');
    for (final track in tracks.take(3)) {
      print(
          '  - ${track.trackName} by ${track.artistName} (${track.duration}s)');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }

  // Example 4: Use SimpMusic with video ID
  print('4. Using SimpMusic with video ID...');
  final simpMusic = lyricals.simpMusic;
  try {
    final data = await simpMusic.getLyricsByVideoId('dQw4w9WgXcQ');
    print('Found ${data.length} lyrics entries');
    for (final entry in data.take(2)) {
      print('  - ${entry.title} by ${entry.artist}');
      print('    Synced: ${entry.syncedLyrics != null}');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }

  // Example 5: Get word-level synced lyrics from BetterLyrics
  print('5. Getting word-level synced lyrics...');
  try {
    final parsed = await lyricals.getParsedLyrics(
      title: 'Never Gonna Give You Up',
      artist: 'Rick Astley',
      duration: 212,
    );
    print('Parsed ${parsed.lines.length} lines');
    if (parsed.lines.isNotEmpty) {
      final firstLine = parsed.lines.first;
      print('First line: "${firstLine.text}" at ${firstLine.startTime}s');
      if (firstLine.words.isNotEmpty) {
        print('Words:');
        for (final word in firstLine.words.take(5)) {
          print('  - "${word.text}" (${word.startTime}s - ${word.endTime}s)');
        }
      }
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }

  // Example 6: Parse existing LRC text (Kotlin-equivalent using LrcLibLyrics)
  print('6. Parsing LRC text with LrcLibLyrics (Kotlin equivalent)...');
  const sampleLrc = '''
[00:00.00]
[00:12.34]First line of the song
[00:15.67]Second line continues
[00:20.89]Third line here
''';

  // Method 1: Using Lyricals.createLyrics (equivalent to Kotlin's Lyrics class)
  final lyricsWrapper = Lyricals.createLyrics(sampleLrc);
  final sentences = lyricsWrapper.sentences;
  if (sentences != null) {
    print('Parsed ${sentences.length} sentences using LrcLibLyrics.sentences:');
    sentences.forEach((timeMs, text) {
      if (text.isNotEmpty) {
        print('  ${timeMs}ms: $text');
      }
    });
  }

  // Method 2: Using static parser
  final sentencesAlt = Lyricals.parseLyricsKotlinStyle(sampleLrc);
  print('Alternative parse: ${sentencesAlt?.length ?? 0} sentences\n');

  // Example 7: Get all lyrics from all sources
  print('7. Getting all lyrics from all sources...');
  var count = 0;
  await lyricals.getAllLyrics(
    title: 'Hello',
    artist: 'Adele',
    duration: 295,
    callback: (lyrics, source) {
      count++;
      print('  Found from $source (${lyrics.length} chars)');
    },
  );
  print('Total: $count lyrics found\n');

  // Example 8: Get lyrics wrapped (Kotlin-equivalent getLyrics returning Lyrics)
  print('8. Getting wrapped lyrics (Kotlin getLyrics equivalent)...');
  try {
    final wrapped = await lyricals.getLyricsWrapped(
      title: 'Yesterday',
      artist: 'The Beatles',
      duration: 125,
    );
    print('Got LrcLibLyrics wrapper');
    final sents = wrapped.sentences;
    if (sents != null) {
      print('Has ${sents.length} sentences');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }

  // Clean up
  lyricals.close();
  print('=== Example Complete ===');
}

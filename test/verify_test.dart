import 'package:dart_lyricals/dart_lyricals.dart';
import 'package:test/test.dart';

void main() {
  group('dart_lyricals package verification', () {
    test('LrcLib: Create instance', () {
      final lrcLib = LrcLib();
      expect(lrcLib, isNotNull);
      lrcLib.close();
    });

    test('SimpMusicLyrics: Create instance', () {
      final simpMusic = SimpMusicLyrics();
      expect(simpMusic, isNotNull);
      simpMusic.close();
    });

    test('BetterLyrics: Create instance', () {
      final betterLyrics = BetterLyrics();
      expect(betterLyrics, isNotNull);
      betterLyrics.close();
    });

    test('Lyricals: Create unified instance', () {
      final lyricals = Lyricals();
      expect(lyricals, isNotNull);
      expect(lyricals.lrcLib, isNotNull);
      expect(lyricals.simpMusic, isNotNull);
      expect(lyricals.betterLyrics, isNotNull);
      lyricals.close();
    });

    test('String Utils: cleanTitle', () {
      expect(cleanTitle('Song Name (Official Video)'), equals('Song Name'));
      expect(cleanTitle('Song [HD]'), equals('Song'));
      expect(cleanTitle('Song feat. Artist'), equals('Song'));
    });

    test('String Utils: cleanArtist', () {
      expect(cleanArtist('Artist feat. Other'), equals('Artist'));
      expect(cleanArtist('Artist & Other'), equals('Artist'));
      expect(cleanArtist('Artist, Other'), equals('Artist'));
    });

    test('String Utils: calculateStringSimilarity', () {
      expect(calculateStringSimilarity('test', 'test'), equals(1.0));
      expect(calculateStringSimilarity('test', ''), equals(0.0));
      expect(calculateStringSimilarity('testing', 'test'), equals(0.8));
    });

    test('LRC Parser: Parse sentences', () {
      const lrc = '[00:00.00]\n[00:12.34]Test line';
      final sentences = LrcParser.parseSentencesKotlinStyle(lrc);
      expect(sentences, isNotNull);
      expect(sentences!.length, greaterThan(1));
    });

    test('LrcLibLyrics: sentences getter', () {
      const lrc = '[00:00.00]\n[00:12.34]Test line';
      final lyrics = LrcLibLyrics(lrc);
      final sentences = lyrics.sentences;
      expect(sentences, isNotNull);
      expect(sentences!.length, greaterThan(1));
    });

    test('TTML Parser: Parse TTML', () {
      const ttml = '''<?xml version="1.0"?>
      <tt><body><div><p begin="0:00.00">Test</p></div></body></tt>''';
      final lines = TTMLParser.parseTTML(ttml);
      expect(lines, isNotEmpty);
      expect(lines.first.text, equals('Test'));
    });

    test('TTML Parser: toLRC', () {
      final lines = [
        ParsedLine(text: 'Hello', startTime: 0.0, words: []),
        ParsedLine(text: 'World', startTime: 1.5, words: []),
      ];
      final lrc = TTMLParser.toLRC(lines);
      expect(lrc, contains('[00:00.00]Hello'));
      expect(lrc, contains('[00:01.50]World'));
    });

    test('Models: LrcLibTrack', () {
      final track = LrcLibTrack(
        id: 1,
        trackName: 'Test',
        artistName: 'Artist',
        duration: 180.0,
      );
      expect(track.hasLyrics, isFalse);
      expect(track.bestLyrics, isNull);
    });

    test('Models: LrcLibTrack with lyrics', () {
      final track = LrcLibTrack(
        id: 1,
        trackName: 'Test',
        artistName: 'Artist',
        duration: 180.0,
        syncedLyrics: '[00:00.00]Test',
      );
      expect(track.hasLyrics, isTrue);
      expect(track.bestLyrics, equals('[00:00.00]Test'));
    });

    test('Models: SimpMusicLyricsData', () {
      final data = SimpMusicLyricsData(
        id: '1',
        videoId: 'test123',
        title: 'Test',
        artist: 'Artist',
      );
      expect(data.hasLyrics, isFalse);
    });

    test('Models: SimpMusicApiResponse', () {
      final response = SimpMusicApiResponse(
        type: 'success',
        data: [],
      );
      expect(response.success, isTrue);
    });

    test('Models: ParsedLyrics', () {
      final parsed = ParsedLyrics(
        text: 'test',
        lines: [],
        isSynced: false,
      );
      expect(parsed.sentences, isNull);
    });

    test('LrcLib extensions: bestMatchingFor', () {
      final tracks = [
        LrcLibTrack(id: 1, trackName: 'A', artistName: 'B', duration: 180.0),
        LrcLibTrack(id: 2, trackName: 'C', artistName: 'D', duration: 200.0, syncedLyrics: 'test'),
      ];
      
      final match = tracks.bestMatchingFor(-1);
      expect(match?.id, equals(2)); // Should prefer synced
    });

    test('Lyricals: createLyrics', () {
      const lrc = '[00:00.00]\n[00:12.34]Test';
      final lyrics = Lyricals.createLyrics(lrc);
      expect(lyrics.sentences, isNotNull);
    });
  });
}

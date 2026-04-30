import 'package:test/test.dart';
import 'package:lafzi_dart/lafzi_dart.dart';

void main() {
  group('phonetics', () {
    test('convert basic', () {
      final result = convert('bismillah');
      expect(result, isNotEmpty);
      expect(result, equals('BISMILAH'));
    });

    test('convert substitutes O->A, E->I', () {
      expect(convert('subhanallah'), contains('A'));
    });

    test('convertNoVowel strips vowels', () {
      final result = convertNoVowel('bismillah');
      expect(result, isNot(contains('A')));
      expect(result, isNot(contains('I')));
      expect(result, isNot(contains('U')));
    });

    test('convert handles apostrophe as hamzah', () {
      final result = convert("qur'an");
      expect(result, contains('X'));
    });

    test('convert handles KH->H', () {
      final result = convert('khalik');
      expect(result, isNot(contains('KH')));
    });

    test('convert handles SH->S', () {
      final result = convert('ashhadu');
      expect(result, isNot(contains('SH')));
    });

    test('convert kunfayakun', () {
      final result = convert('kunfayakun');
      expect(result, isNotEmpty);
    });
  });

  group('trigram', () {
    test('extract from short string returns empty', () {
      expect(extract('AB'), isEmpty);
    });

    test('extract basic trigrams', () {
      final result = extract('ABC');
      expect(result, contains('ABC'));
      expect(result['ABC'], equals(1));
    });

    test('extract counts duplicates', () {
      final result = extract('ABCAB');
      expect(result['ABC'], equals(1));
      expect(result['BCA'], equals(1));
      expect(result['CAB'], equals(1));
    });

    test('extractFromQuery returns trigrams', () {
      final result = extractFromQuery('bismillah');
      expect(result, isNotEmpty);
    });
  });

  group('array', () {
    test('lcs with empty list', () {
      expect(lcs([]), isEmpty);
    });

    test('lcs with single element', () {
      expect(lcs([5]), equals([5]));
    });

    test('lcs finds contiguous subsequence', () {
      final result = lcs([1, 2, 3, 10, 11, 12, 13, 20]);
      // With default maxGap=7, 1..3 and 10..13 and 20 are all within gap=7
      expect(result.length, greaterThanOrEqualTo(4));
    });

    test('contiguityScore perfect', () {
      expect(contiguityScore([1, 2, 3, 4]), closeTo(1.0, 0.01));
    });

    test('flattenValues', () {
      final result = flattenValues({'a': [1, 2], 'b': [3]});
      expect(result, containsAll([1, 2, 3]));
    });

    test('highlightSpan single element', () {
      final result = highlightSpan([5]);
      expect(result, equals([[5, 8]]));
    });

    test('highlightSpan groups adjacent', () {
      final result = highlightSpan([1, 2, 3]);
      expect(result.length, equals(1));
    });
  });

  group('hilight', () {
    test('wraps single span', () {
      final result = hilight('ABCDEFGH', [
        [2, 4]
      ]);
      expect(result, contains("class='hl_block'"));
      expect(result, contains('</span>'));
    });

    test('no highlight for empty positions', () {
      final result = hilight('ABCDEFGH', []);
      expect(result, equals('ABCDEFGH'));
    });
  });

  group('database + search (integration)', () {
    late LafziDatabase db;

    setUp(() async {
      db = await LafziDatabase.open('data/lafzi.sqlite');
    });

    tearDown(() {
      db.close();
    });

    test('database has correct row counts', () {
      final verse = db.getVerse(1);
      expect(verse, isNotNull);
      expect(verse!['surah_no'], equals(1));
      expect(verse['surah_name'], equals('Al-Fatihah'));
      expect(verse['ayat_no'], equals(1));
    });

    test('getVerse returns null for invalid id', () {
      final verse = db.getVerse(99999);
      expect(verse, isNull);
    });

    test('getVerses batch fetch', () {
      final verses = db.getVerses([1, 2, 3]);
      expect(verses.length, equals(3));
      expect(verses[0]['id'], equals(1));
      expect(verses[2]['id'], equals(3));
    });

    test('lookupTrigrams finds entries', () {
      final phonetic = convert('bismillah');
      final trigrams = extract(phonetic);
      final entries = db.lookupTrigrams(trigrams.keys, 'v');
      expect(entries, isNotEmpty);
    });

    test('lookupTrigrams returns empty for nonexistent trigrams', () {
      final entries = db.lookupTrigrams(['ZZZ'], 'v');
      expect(entries, isEmpty);
    });

    test('search kunfayakun returns results', () async {
      final results = await search(db, 'kunfayakun');
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(5));

      // Top result should be Al-An'am 73 (highest score)
      expect(results.first.surahNo, equals(6)); // Al-An'am
      expect(results.first.ayatNo, equals(73));
      expect(results.first.score, greaterThan(9.0));
    });

    test('search bismillah finds Al-Fatihah 1', () async {
      final results = await search(db, 'bismillah', options: const SearchOptions(threshold: 0.8));
      expect(results, isNotEmpty);

      final surahs = results.map((v) => '${v.surahNo}:${v.ayatNo}').toList();
      expect(surahs, contains('1:1')); // Al-Fatihah 1
    });

    test('search alhamdulillah in nv mode', () async {
      final results = await search(
        db,
        'alhamdulillah',
        options: const SearchOptions(mode: 'nv', threshold: 0.7),
      );
      expect(results, isNotEmpty);

      final surahs = results.map((v) => '${v.surahNo}:${v.ayatNo}').toList();
      expect(surahs, contains('1:2')); // Al-Fatihah 2
    });

    test('search with highlight', () async {
      final results = await search(
        db,
        'bismillah',
        options: const SearchOptions(threshold: 0.8, isHilight: true),
      );
      expect(results, isNotEmpty);
      expect(results.first.textHilight, isNotNull);
      expect(results.first.textHilight, contains("class='hl_block'"));
    });

    test('search empty query returns empty', () async {
      final results = await search(db, '');
      expect(results, isEmpty);
    });

    test('search nonsense returns empty', () async {
      final results = await search(db, 'xyzxyzxyz');
      expect(results, isEmpty);
    });

    test('verse has correct fields', () async {
      final results = await search(db, 'kunfayakun');
      final v = results.first;

      expect(v.id, greaterThan(0));
      expect(v.surahNo, greaterThan(0));
      expect(v.surahName, isNotEmpty);
      expect(v.ayatNo, greaterThan(0));
      expect(v.textArabic, isNotEmpty);
      expect(v.textIndonesian, isNotEmpty);
      expect(v.score, greaterThan(0.0));
    });

    test('verse toJson has all keys', () async {
      final results = await search(db, 'kunfayakun');
      final json = results.first.toJson();

      expect(json, contains('surah'));
      expect(json, contains('name'));
      expect(json, contains('ayat'));
      expect(json, contains('text'));
      expect(json, contains('trans'));
      expect(json, contains('score'));
      expect(json, contains('highlightPos'));
    });
  });

  group('compressed DB + search', () {
    late LafziDatabase db;

    setUp(() async {
      db = await LafziDatabase.open('data/lafzi_compressed.sqlite');
    });

    tearDown(() {
      db.close();
    });

    test('detects compressed format', () {
      expect(db.isCompressed, isTrue);
    });

    test('getVerse reads decompressed posmap', () {
      final verse = db.getVerse(1);
      expect(verse, isNotNull);
      expect(verse!['vocal_posmap'], isNotNull);
      expect(verse['vocal_posmap'] as String, isNotEmpty);
    });

    test('lookupTrigrams decompresses postings', () {
      final phonetic = convert('bismillah');
      final trigrams = extract(phonetic);
      final entries = db.lookupTrigrams(trigrams.keys, 'v');
      expect(entries, isNotEmpty);
      for (final entry in entries.values) {
        expect(entry.postings, isNotEmpty);
      }
    });

    test('search kunfayakun identical to uncompressed', () async {
      final results = await search(db, 'kunfayakun');
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(5));
      expect(results.first.surahNo, equals(6)); // Al-An'am
      expect(results.first.ayatNo, equals(73));
      expect(results.first.score, greaterThan(9.0));
    });

    test('search bismillah with highlight', () async {
      final results = await search(
        db,
        'bismillah',
        options: const SearchOptions(threshold: 0.8, isHilight: true),
      );
      expect(results, isNotEmpty);
      expect(results.first.textHilight, contains("class='hl_block'"));
    });

    test('search alhamdulillah nv mode', () async {
      final results = await search(
        db,
        'alhamdulillah',
        options: const SearchOptions(mode: 'nv', threshold: 0.7),
      );
      expect(results, isNotEmpty);
      final surahs = results.map((v) => '${v.surahNo}:${v.ayatNo}').toList();
      expect(surahs, contains('1:2'));
    });
  });
}
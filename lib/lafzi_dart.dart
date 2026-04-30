/// Lafzi - Al-Quran phonetic search engine.
///
/// Pure Dart library for searching Quran verses by Latin transliteration
/// using phonetic matching and trigram indexing.
///
/// ```dart
/// import 'package:lafzi_dart/lafzi_dart.dart';
///
/// final db = await LafziDatabase.open('path/to/lafzi.sqlite');
/// final results = await search(db, 'kunfayakun');
/// for (final v in results) {
///   print('${v.surahName} ${v.ayatNo}: ${v.textArabic}');
/// }
/// db.close();
/// ```
library;

// Public API
export 'src/phonetics.dart' show convert, convertNoVowel;
export 'src/trigram.dart' show extract, extractFromQuery;
export 'src/array.dart' show lcs, contiguityScore, flattenValues, highlightSpan;
export 'src/database.dart' show LafziDatabase, QuranVerse, TrigramEntry;
export 'src/searcher.dart' show search, SearchOptions;
export 'src/hilight.dart' show hilight;
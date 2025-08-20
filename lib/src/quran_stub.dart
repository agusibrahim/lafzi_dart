import 'models.dart';

/// Verse counts for each surah in the Quran.
/// Source: https://github.com/semarketir/quranjson
const List<int> _surahVerseCounts = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
  111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
  54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
  49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
  44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
  26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6,
  3, 5, 4, 5, 6
];

/// Generates a stub of [QuranVerse] entries containing only surah and ayat
/// numbers. Text and translation fields are left empty.
List<QuranVerse> generateEmptyQuran() {
  final result = <QuranVerse>[];
  for (int s = 0; s < _surahVerseCounts.length; s++) {
    final surah = s + 1;
    final ayatCount = _surahVerseCounts[s];
    for (int ayat = 1; ayat <= ayatCount; ayat++) {
      result.add(QuranVerse(
        surah: surah,
        name: '',
        ayat: ayat,
        text: '',
        trans: '',
      ));
    }
  }
  return result;
}

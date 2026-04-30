/// Trigram extraction for phonetic search indexing.
library;

import 'phonetics.dart';

/// Extracts trigrams from a phonetic string.
/// Returns map of trigram -> frequency.
Map<String, int> extract(String phonetic) {
  final result = <String, int>{};
  if (phonetic.length < 3) return result;

  for (var i = 0; i <= phonetic.length - 3; i++) {
    final tri = phonetic.substring(i, i + 3);
    result[tri] = (result[tri] ?? 0) + 1;
  }
  return result;
}

/// Convenience: convert query then extract trigrams.
Map<String, int> extractFromQuery(String query, {bool withVowel = true}) {
  final phonetic = withVowel ? convert(query) : convertNoVowel(query);
  return extract(phonetic);
}
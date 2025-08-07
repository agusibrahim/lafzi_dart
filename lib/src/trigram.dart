/// Extracts trigrams from a string.
/// @param input The input string.
/// @returns A list of trigrams.
List<String> trigram(String input) {
  final s = input.trim();
  final length = s.length;

  if (length < 3) return [];
  if (length == 3) return [s];

  final trigrams = <String>[];
  for (int i = 0; i <= length - 3; i++) {
    trigrams.add(s.substring(i, i + 3));
  }

  return trigrams;
}

/// Extracts trigrams with their frequencies.
/// @param input The input string.
/// @returns A map where keys are trigrams and values are their frequencies.
Map<String, int> extract(String input) {
  final trig = trigram(input);
  final acc = <String, int>{};
  for (final e in trig) {
    acc[e] = (acc.containsKey(e) ? acc[e]! + 1 : 1);
  }
  return acc;
}

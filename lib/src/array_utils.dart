
extension ListIntExtension on List<int> {
  List<int> unique() {
    return toSet().toList();
  }
}

/// Calculates the contiguity score for a given array of numbers.
/// @param arr The input array of numbers.
/// @returns The contiguity score.
double contiguityScore(List<int> arr) {
  final len = arr.length;

  if (len == 1) return 1.0;

  final diff = <double>[];
  for (int i = 0; i < len - 1; i++) {
    diff.add(1.0 / (arr[i + 1] - arr[i]));
  }

  final sum = diff.reduce((a, b) => a + b);
  return sum / (len - 1);
}

/// Longest Contiguous Subsequence
/// @param seq The input sequence of numbers.
/// @param maxgap The maximum allowed gap between numbers in the subsequence. Defaults to 7.
/// @returns The longest contiguous subsequence.
List<int> lcs(List<int> seq, [int maxgap = 7]) {
  seq.sort((a, b) => a - b);
  final size = seq.length;
  int start = 0, length = 0, maxstart = 0, maxlength = 0;

  for (int i = 0; i < size - 1; i++) {
    if ((seq[i + 1] - seq[i]) > maxgap) {
      length = 0;
      start = i + 1;
    } else {
      length++;
      if (length > maxlength) {
        maxlength = length;
        maxstart = start;
      }
    }
  }

  maxlength++;

  return seq.sublist(maxstart, maxstart + maxlength);
}

/// Flattens the values of an object (Map) into a single list.
/// @param obj The input object (Map) with List<int> values.
/// @returns A flattened list of numbers.
List<int> flattenValues(Map<String, List<int>> obj) {
  final result = <int>[];
  obj.forEach((key, value) {
    result.addAll(value);
  });
  return result;
}

/// Calculates highlight spans for a given sequence.
/// @param hlSequence The input highlight sequence.
/// @param minLength The minimum length for a highlight span. Defaults to 3.
/// @returns A list of highlight spans.
List<List<int>> highlightSpan(List<int> hlSequence, [int minLength = 3]) {
  final len = hlSequence.length;
  if (len == 1) {
    return [
      [hlSequence[0], hlSequence[0] + minLength]
    ];
  }

  hlSequence.sort((a, b) => a - b);

  final result = <List<int>>[];
  int j = 1;

  for (int i = 0; i < len; i++) {
    while (j < len && (hlSequence[j] - hlSequence[j - 1]) <= minLength + 1) {
      j++;
    }
    result.add([hlSequence[i], hlSequence[j - 1]]);
    i = j - 1;
    j++;
  }

  return result;
}

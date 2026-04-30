/// Array utilities for search: LCS, contiguity score, flatten, highlight span.
library;

/// Longest Contiguous Subsequence.
/// Finds the longest subsequence where consecutive elements are within [maxGap].
List<int> lcs(List<int> seq, {int maxGap = 7}) {
  if (seq.isEmpty) return [];
  if (seq.length == 1) return List.of(seq);

  final sorted = List<int>.of(seq)..sort();
  var start = 0;
  var length = 0;
  var maxStart = 0;
  var maxLength = 0;

  for (var i = 0; i < sorted.length - 1; i++) {
    if (sorted[i + 1] - sorted[i] > maxGap) {
      length = 0;
      start = i + 1;
    } else {
      length++;
      if (length > maxLength) {
        maxLength = length;
        maxStart = start;
      }
    }
  }
  maxLength++;
  return sorted.sublist(maxStart, maxStart + maxLength);
}

/// Contiguity score: measures how contiguous the sequence is.
/// Returns 1.0 for perfectly contiguous, lower for gaps.
double contiguityScore(List<int> arr) {
  if (arr.length <= 1) return 1.0;

  var sum = 0.0;
  for (var i = 0; i < arr.length - 1; i++) {
    sum += 1.0 / (arr[i + 1] - arr[i]);
  }
  return sum / (arr.length - 1);
}

/// Flattens a map of position lists into a single list.
List<int> flattenValues(Map<String, List<int>> obj) {
  final result = <int>[];
  for (final positions in obj.values) {
    result.addAll(positions);
  }
  return result;
}

/// Groups highlight positions into spans.
/// Adjacent positions within [minLength] are merged into a single span.
List<List<int>> highlightSpan(List<int> hlSequence, {int minLength = 3}) {
  if (hlSequence.isEmpty) return [];
  if (hlSequence.length == 1) return [[hlSequence[0], hlSequence[0] + minLength]];

  final sorted = List<int>.of(hlSequence)..sort();
  final result = <List<int>>[];
  var j = 1;

  for (var i = 0; i < sorted.length; i++) {
    while (j < sorted.length && sorted[j] - sorted[j - 1] <= minLength + 1) {
      j++;
    }
    result.add([sorted[i], sorted[j - 1]]);
    i = j - 1;
    j++;
  }
  return result;
}
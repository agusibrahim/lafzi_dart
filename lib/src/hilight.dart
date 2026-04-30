/// Text highlighting for search results.
library;

/// Wraps matched regions with highlight tags.
/// Works backwards to preserve character positions.
String hilight(String text, List<List<int>> posArray) {
  final chars = text.split('');
  const openTag = "<span class='hl_block'>";
  const closeTag = '</span>';

  // Process in reverse to keep positions stable
  for (var i = posArray.length - 1; i >= 0; i--) {
    final start = posArray[i][0];
    var end = posArray[i][1] + 1;

    if (start >= chars.length) continue;
    if (end > chars.length) end = chars.length;

    chars.insert(end, closeTag);
    chars.insert(start, openTag);
  }

  return chars.join('');
}
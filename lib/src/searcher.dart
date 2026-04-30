/// Core search engine for Lafzi.
///
/// Pipeline: query -> phonetic convert -> trigram extract ->
///           index lookup -> match -> LCS rank -> prepare results
library;

import 'dart:convert';
import 'dart:math';

import 'array.dart' as arr;
import 'database.dart' show LafziDatabase, QuranVerse, TrigramEntry;
import 'hilight.dart' show hilight;
import 'phonetics.dart' show convert, convertNoVowel;
import 'trigram.dart' show extract;

/// Internal match document during search.
class _MatchDoc {
  int id = 0;
  int matchCount = 0;
  double contigScore = 0;
  double score = 0;
  Map<String, List<int>> matchTerms = {};
  List<int> lcsResult = [];
  List<List<int>> highlightPos = [];
}

/// Search options.
class SearchOptions {
  /// 'v' = with vowel, 'nv' = no vowel
  final String mode;

  /// Minimum match threshold (0.0 - 1.0)
  final double threshold;

  /// Whether to generate highlighted text
  final bool isHilight;

  /// Whether to return all highlight spans (true) or just the best (false)
  final bool multipleHighlightPos;

  const SearchOptions({
    this.mode = 'v',
    this.threshold = 0.95,
    this.isHilight = true,
    this.multipleHighlightPos = false,
  });
}

/// Performs a full search against the database.
///
/// Returns ranked list of [QuranVerse] matching the query.
Future<List<QuranVerse>> search(
  LafziDatabase db,
  String query, {
  SearchOptions options = const SearchOptions(),
}) async {
  // 1. Clean query
  final cleaned = _cleanQuery(query);
  if (cleaned == null || cleaned.isEmpty) return [];

  // 2. Convert to phonetic + extract trigrams
  final phonetic =
      options.mode == 'v' ? convert(cleaned) : convertNoVowel(cleaned);
  final queryTrigrams = extract(phonetic);
  if (queryTrigrams.isEmpty) return [];

  // 3. Lookup trigrams in index
  final indexEntries = db.lookupTrigrams(queryTrigrams.keys, options.mode);

  // 4. Match documents
  var matchedDocs = _matchDocuments(queryTrigrams, indexEntries);

  // 5. Score and filter
  var threshold = options.threshold;
  final trigramCount = queryTrigrams.length;
  var filtered = _scoreAndFilter(matchedDocs, threshold, trigramCount);

  // 6. Retry with relaxed threshold if no results
  if (filtered.isEmpty) {
    threshold = _optimizeThreshold(threshold);
    filtered = _scoreAndFilter(matchedDocs, threshold, trigramCount);
  }
  if (filtered.isEmpty && threshold != _optimizeThreshold(threshold)) {
    threshold = _optimizeThreshold(threshold);
    filtered = _scoreAndFilter(matchedDocs, threshold, trigramCount);
  }

  if (filtered.isEmpty) return [];

  // 7. Rank: resolve highlight positions from posmap
  final ranked = _rank(
    filtered,
    db,
    options.mode,
    multipleHighlightPos: options.multipleHighlightPos,
  );

  // 8. Prepare final results
  return _prepare(
    ranked,
    db,
    isHilight: options.isHilight,
    multipleHighlightPos: options.multipleHighlightPos,
  );
}

// --- Internal helpers ---

String? _cleanQuery(String? query) {
  if (query == null || query.trim().isEmpty) return null;
  return Uri.decodeComponent(query.trim()).replaceAll(RegExp(r'[-+]'), ' ');
}

double _optimizeThreshold(double t) {
  var tmp = (double.parse(t.toStringAsPrecision(2)) * 10).roundToDouble();
  if (tmp - 1 != 0) {
    return (--tmp) / 10;
  }
  return t;
}

/// Step 4: Match documents from trigram postings.
Map<int, _MatchDoc> _matchDocuments(
  Map<String, int> queryTrigrams,
  Map<String, TrigramEntry> indexEntries,
) {
  final docs = <int, _MatchDoc>{};

  for (final entry in queryTrigrams.entries) {
    final trigram = entry.key;
    final triFreq = entry.value;
    final idxEntry = indexEntries[trigram];
    if (idxEntry == null) continue;

    for (final posting in idxEntry.postings.entries) {
      final docId = posting.key;
      final positions = posting.value;
      final docFreq = positions.length;

      if (docs.containsKey(docId)) {
        docs[docId]!.matchCount += min(triFreq, docFreq);
      } else {
        docs[docId] = _MatchDoc()
          ..id = docId
          ..matchCount = 1;
      }

      docs[docId]!.matchTerms[trigram] = positions;
    }
  }

  return docs;
}

/// Step 5: Score with LCS + contiguity, filter by threshold.
List<_MatchDoc> _scoreAndFilter(
  Map<int, _MatchDoc> docs,
  double threshold,
  int trigramCount,
) {
  final minScore = (threshold * trigramCount).toStringAsPrecision(2);
  final minScoreVal = double.parse(minScore);

  final result = <_MatchDoc>[];

  for (final doc in docs.values) {
    final flat = arr.flattenValues(doc.matchTerms);
    final lcsResult = arr.lcs(flat);
    final orderScore = lcsResult.length.toDouble();

    doc.lcsResult = lcsResult;
    doc.contigScore = arr.contiguityScore(lcsResult);
    doc.score = orderScore * doc.contigScore;

    if (doc.score >= minScoreVal) {
      result.add(doc);
    }
  }

  return result;
}

/// Step 7: Resolve highlight positions from position maps.
List<_MatchDoc> _rank(
  List<_MatchDoc> docs,
  LafziDatabase db,
  String mode, {
  bool multipleHighlightPos = false,
}) {
  // Batch fetch verses for posmaps
  final ids = docs.map((d) => d.id).toList();
  final verses = db.getVerses(ids);
  final verseMap = <int, Map<String, dynamic>>{};
  for (final v in verses) {
    verseMap[v['id'] as int] = v;
  }

  for (final doc in docs) {
    final verse = verseMap[doc.id];
    if (verse == null) continue;

    // Parse posmap
    final posmapKey = mode == 'v' ? 'vocal_posmap' : 'nonvocal_posmap';
    final posmapStr = verse[posmapKey] as String?;
    if (posmapStr == null || posmapStr.isEmpty) continue;

    final posmap = posmapStr
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();

    // Build real positions from LCS
    final seq = <int>[];
    for (final pos in doc.lcsResult) {
      seq.add(pos);
      seq.add(pos + 1);
      seq.add(pos + 2);
    }
    final uniqueSeq = seq.toSet().toList()..sort();

    final realPos = <int>[];
    for (final s in uniqueSeq) {
      if (s - 1 < posmap.length) {
        realPos.add(posmap[s - 1]);
      }
    }

    // Compute highlight spans
    var hlSpans = arr.highlightSpan(realPos);
    hlSpans = hlSpans
        .where((s) => s[0] != null && s.length > 1 && s[1] != null)
        .toList();

    doc.highlightPos = hlSpans;

    // Extend highlight at word boundaries
    final docText = verse['ayat_arabic'] as String;
    if (docText.isNotEmpty && hlSpans.isNotEmpty) {
      if (multipleHighlightPos) {
        for (var k = 0; k < doc.highlightPos.length; k++) {
          final endPos = doc.highlightPos[k][1];
          if (endPos + 3 < docText.length) {
            if (docText[endPos + 1] == ' ' ||
                docText[endPos + 2] == ' ' ||
                docText[endPos + 3] == ' ') {
              doc.highlightPos[k][1] += 2;
            }
          }
        }
      } else {
        final endPos = doc.highlightPos.last[1];
        if (endPos + 3 < docText.length) {
          if (docText[endPos + 1] == ' ' ||
              docText[endPos + 2] == ' ' ||
              docText[endPos + 3] == ' ') {
            doc.highlightPos[doc.highlightPos.length - 1][1] += 2;
          }
        }
      }
    }
  }

  // Sort by score descending
  docs.sort((a, b) => b.score.compareTo(a.score));
  return docs;
}

/// Step 8: Build final QuranVerse results.
List<QuranVerse> _prepare(
  List<_MatchDoc> ranked,
  LafziDatabase db, {
  bool isHilight = true,
  bool multipleHighlightPos = false,
}) {
  // Batch fetch verses
  final ids = ranked.map((d) => d.id).toList();
  final verses = db.getVerses(ids);
  final verseMap = <int, Map<String, dynamic>>{};
  for (final v in verses) {
    verseMap[v['id'] as int] = v;
  }

  final result = <QuranVerse>[];

  for (final doc in ranked) {
    final verse = verseMap[doc.id];
    if (verse == null) continue;

    var text = verse['ayat_arabic'] as String;
    final muqathaat = verse['muqathaat'] as String?;

    final hlPos = multipleHighlightPos
        ? doc.highlightPos
        : doc.highlightPos.isEmpty
            ? <List<int>>[]
            : [doc.highlightPos.first];

    String? textHilight;
    if (isHilight && hlPos.isNotEmpty) {
      textHilight = hilight(text, hlPos);
    }

    result.add(QuranVerse(
      id: doc.id,
      surahNo: verse['surah_no'] as int,
      surahName: verse['surah_name'] as String,
      ayatNo: verse['ayat_no'] as int,
      textArabic: text,
      textIndonesian: verse['ayat_indonesian'] as String,
      muqathaatText: muqathaat,
      highlightPositions: hlPos.expand((e) => e).toList(),
      score: doc.score,
      textHilight: textHilight,
    ));
  }

  return result;
}
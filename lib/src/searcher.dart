import 'dart:math';

import 'package:lafzi_dart/src/array_utils.dart';
import 'package:lafzi_dart/src/models.dart';
import 'package:lafzi_dart/src/phonetic.dart' as phonetic;
import 'package:lafzi_dart/src/trigram.dart' as trigram;
import 'package:lafzi_dart/src/hilight.dart';

/// Performs the search operation.
/// @param docIndex The document index (Map of trigrams to IndexEntry lists).
/// @param query The search query string.
/// @param threshold The minimum score threshold for results.
/// @param mode The search mode ('v' for vowel, 'nv' for no vowel).
/// @returns A Future that resolves with a list of LafziDocument objects.
Future<List<LafziDocument>> search(
  Map<String, List<IndexEntry>> docIndex,
  String query,
  double threshold,
  String mode,
) async {
  String queryFinal;

  if (mode == 'v') {
    queryFinal = phonetic.convert(query);
  } else {
    queryFinal = phonetic.convertNoVowel(query);
  }

  final queryTrigrams = trigram.extract(queryFinal);
  if (queryTrigrams.isEmpty) {
    return [];
  }

  final matchedDocs = <int, LafziDocument>{};

  queryTrigrams.forEach((trigram, trigramFreq) {
    if (docIndex.containsKey(trigram) && docIndex[trigram] != null) {
      final indexEntry = docIndex[trigram]!;
      for (final match in indexEntry) {
        if (matchedDocs.containsKey(match.docID)) {
          matchedDocs[match.docID]!.matchCount +=
              min(trigramFreq, match.freq);
        } else {
          matchedDocs[match.docID] = LafziDocument(
            id: match.docID,
            matchCount: 1,
          );
        }
        matchedDocs[match.docID]!.matchTerms[trigram] = match.pos;
      }
    }
  });

  final filteredDocs = <LafziDocument>[];
  final minScore = (threshold * queryTrigrams.keys.length);

  for (final docID in matchedDocs.keys) {
    final doc = matchedDocs[docID]!;

    final lcsResult = lcs(flattenValues(doc.matchTerms));
    final orderScore = lcsResult.length;

    doc.lcs = lcsResult;
    doc.contigScore = contiguityScore(lcsResult);
    doc.score = orderScore * doc.contigScore;

    if (doc.score >= minScore) {
      filteredDocs.add(doc);
    }
  }

  return filteredDocs;
}

/// Ranks the search results.
/// @param filteredDocs A list of LafziDocument objects from the search phase.
/// @param posmapData The position mapping data.
/// @param quranTextData The Quran text data.
/// @param multipleHighlightPos Whether to allow multiple highlight positions.
/// @returns A Future that resolves with a ranked list of LafziDocument objects.
Future<List<LafziDocument>> rank(
  List<LafziDocument> filteredDocs,
  List<List<int>> posmapData,
  List<QuranVerse> quranTextData,
  {bool multipleHighlightPos = false,}
) async {
  for (final doc in filteredDocs) {
    final realPos = <int>[];
    final posmap = posmapData[doc.id - 1];
    final seq = <int>[];

    for (final pos in doc.lcs) {
      seq.add(pos);
      seq.add(pos + 1);
      seq.add(pos + 2);
    }
    final uniqueSeq = seq.unique();

    for (final pos in uniqueSeq) {
      if (pos - 1 >= 0 && pos - 1 < posmap.length) {
        realPos.add(posmap[pos - 1]);
      }
    }

    // Additional highlight custom
    final tmpHighlight = highlightSpan(realPos, 6);
    doc.highlightPos = tmpHighlight.where((o) => o[0] != null && o[1] != null).toList();

    // Additional scoring based on space
    if (quranTextData.isNotEmpty && doc.highlightPos.isNotEmpty) {
      if (multipleHighlightPos) {
        for (int k = 0; k < doc.highlightPos.length; k++) {
          final endPos = doc.highlightPos[k][1];
          if (doc.id - 1 < quranTextData.length) {
            final docText = quranTextData[doc.id - 1].text;
            if (endPos + 1 < docText.length && docText[endPos + 1] == ' ' ||
                endPos + 2 < docText.length && docText[endPos + 2] == ' ' ||
                endPos + 3 < docText.length && docText[endPos + 3] == ' ') {
              doc.highlightPos[k][1] += 2; // Add 2 characters
            }
          }
        }
      } else {
        final endPos = doc.highlightPos.last[1];
        if (doc.id - 1 < quranTextData.length) {
          final docText = quranTextData[doc.id - 1].text;
          if (endPos + 1 < docText.length && docText[endPos + 1] == ' ' ||
              endPos + 2 < docText.length && docText[endPos + 2] == ' ' ||
              endPos + 3 < docText.length && docText[endPos + 3] == ' ') {
            doc.highlightPos[0][1] += 2; // Add 2 characters
          }
        }
      }
    }

    // Clear temporary data
    doc.lcs = [];
    doc.matchTerms = {};
    doc.contigScore = 0.0;
  }

  filteredDocs.sort((docA, docB) => docB.score.compareTo(docA.score));

  return filteredDocs;
}

/// Prepares the search result for view.
/// @param rankedSearchResult A list of ranked LafziDocument objects.
/// @param quranTextData The Quran text data.
/// @param muqathaatData Optional muqathaat data.
/// @param isHilight Whether to apply highlighting.
/// @param multipleHighlightPos Whether to allow multiple highlight positions.
/// @returns A Future that resolves with a list of QuranVerse objects with search results.
Future<List<QuranVerse>> prepare(
  List<LafziDocument> rankedSearchResult,
  List<QuranVerse> quranTextData,
  {Map<int, Map<int, String>>? muqathaatData,
  bool isHilight = true,
  bool multipleHighlightPos = false,}
) async {
  final result = <QuranVerse>[];
  for (final searchRes in rankedSearchResult) {
    if (searchRes.id - 1 < quranTextData.length) {
      final quranData = quranTextData[searchRes.id - 1];
      var obj = QuranVerse(
        surah: quranData.surah,
        name: quranData.name,
        ayat: quranData.ayat,
        text: quranData.text,
        trans: quranData.trans,
        score: searchRes.score,
        highlightPos: searchRes.highlightPos,
      );

      if (muqathaatData != null &&
          muqathaatData.containsKey(obj.surah) &&
          muqathaatData[obj.surah]!.containsKey(obj.ayat)) {
        obj=obj.copyWith(text: muqathaatData[obj.surah]![obj.ayat]!);
      }

      obj.highlightPos = (multipleHighlightPos) ? obj.highlightPos : obj.highlightPos?.take(1).toList();

      // Hilight feature
      if (isHilight && obj.highlightPos != null) {
        obj.textHilight = hilight(obj.text, obj.highlightPos!); // Pass non-null highlightPos
      }
      result.add(obj);
    }
  }

  return result;
}

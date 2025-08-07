import 'dart:convert';
import 'package:lafzi_dart/src/models.dart';

/// Parse Lafzi text data to some defined structures
/// @param buffer The raw string content of muqathaat.txt
/// @returns A Map where keys are surah numbers and values are Maps of ayat numbers to text.
Map<int, Map<int, String>> parseMuqathaat(String buffer) {
  final lines = buffer.split('\n');
  final result = <int, Map<int, String>>{};
  for (final line in lines) {
    final data = line.split('|');
    if (data.length >= 4) {
      final noSurat = int.tryParse(data[0]);
      final noAyat = int.tryParse(data[2]);
      final text = data[3];

      if (noSurat != null && noAyat != null) {
        result.putIfAbsent(noSurat, () => {});
        result[noSurat]![noAyat] = text;
      }
    }
  }
  return result;
}

/// Parses Quran text and translation buffers into a list of QuranVerse objects.
/// @param bufferText The raw string content of quran_teks.txt
/// @param bufferTrans The raw string content of quran_trans_indonesian.txt
/// @returns A list of QuranVerse objects.
List<QuranVerse> parseQuran(String bufferText, String bufferTrans) {
  final lineText = bufferText.split('\n');
  final lineTrans = bufferTrans.split('\n');
  final result = <QuranVerse>[];

  for (int i = 0; i < lineText.length; i++) {
    if (i >= lineTrans.length) continue; // Ensure translation line exists

    final dataText = lineText[i].split('|');
    final dataTrans = lineTrans[i].split('|');

    if (dataText.length >= 4 && dataTrans.length >= 3) {
      final surah = int.tryParse(dataText[0]);
      final name = dataText[1];
      final ayat = int.tryParse(dataText[2]);
      final text = dataText[3];
      final trans = dataTrans[2];

      if (surah != null && ayat != null) {
        result.add(QuranVerse(
          surah: surah,
          name: name,
          ayat: ayat,
          text: text,
          trans: trans,
        ));
      }
    }
  }
  return result;
}

/// Converts a comma-delimited string to a list of integers.
List<int> _strToIntArray(String str) {
  return str.split(',').map((val) => int.tryParse(val) ?? 0).toList();
}

/// Parses a buffer into a list of lists of integers (posmap data).
/// @param buffer The raw string content of posmap_v.txt or posmap_nv.txt
/// @returns A list of lists of integers.
List<List<int>> parsePosmap(String buffer) {
  final lines = buffer.split('\n');
  final result = <List<int>>[];
  for (final line in lines) {
    if (line.trim().isNotEmpty) {
      result.add(_strToIntArray(line));
    }
  }
  return result;
}

/// Parses a JSON buffer into a Map of trigrams to lists of IndexEntry objects.
/// @param buffer The raw string content of index_v.jsn or index_nv.jsn
/// @returns A Map where keys are trigrams and values are lists of IndexEntry objects.
Map<String, List<IndexEntry>> parseIndex(String buffer) {
  final Map<String, dynamic> decoded = jsonDecode(buffer);
  final result = <String, List<IndexEntry>>{};
  decoded.forEach((key, value) {
    result[key] = (value as List<dynamic>)
        .map((e) => IndexEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  });
  return result;
}

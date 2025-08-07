
import 'dart:convert';

class QuranVerse {
  final int surah;
  final String name;
  final int ayat;
  final String text;
  final String trans;
  String? textHilight; // Optional, for highlighted text
  double? score; // Optional, for search results
  List<List<int>>? highlightPos; // Optional, for highlight positions

  QuranVerse({
    required this.surah,
    required this.name,
    required this.ayat,
    required this.text,
    required this.trans,
    this.textHilight,
    this.score,
    this.highlightPos,
  });

  factory QuranVerse.fromJson(Map<String, dynamic> json) {
    return QuranVerse(
      surah: json['surah'] as int,
      name: json['name'] as String,
      ayat: json['ayat'] as int,
      text: json['text'] as String,
      trans: json['trans'] as String,
      textHilight: json['text_hilight'] as String?,
      score: json['score'] as double?,
      highlightPos: (json['highlightPos'] as List<dynamic>?)
          ?.map((e) => (e as List<dynamic>).map((x) => x as int).toList())
          .toList(),
    );
  }
  QuranVerse copyWith({
    int? surah,
    String? name,
    int? ayat,
    String? text,
    String? trans,
    String? textHilight,
    double? score,
    List<List<int>>? highlightPos,
  }) {
    return QuranVerse(
      surah: surah ?? this.surah,
      name: name ?? this.name,
      ayat: ayat ?? this.ayat,
      text: text ?? this.text,
      trans: trans ?? this.trans,
      textHilight: textHilight ?? this.textHilight,
      score: score ?? this.score,
      highlightPos: highlightPos ?? this.highlightPos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah': surah,
      'name': name,
      'ayat': ayat,
      'text': text,
      'trans': trans,
      if (textHilight != null) 'text_hilight': textHilight,
      if (score != null) 'score': score,
      if (highlightPos != null) 'highlightPos': highlightPos,
    };
  }
}

class LafziDocument {
  int id;
  int matchCount;
  double contigScore;
  double score;
  Map<String, List<int>> matchTerms;
  List<int> lcs;
  List<List<int>> highlightPos;

  LafziDocument({
    this.id = 0,
    this.matchCount = 0,
    this.contigScore = 0.0,
    this.score = 0.0,
    Map<String, List<int>>? matchTerms,
    List<int>? lcs,
    List<List<int>>? highlightPos,
  })  : matchTerms = matchTerms ?? {},
        lcs = lcs ?? [],
        highlightPos = highlightPos ?? [];
}

class IndexEntry {
  final int docID;
  final int freq;
  final List<int> pos;

  IndexEntry({
    required this.docID,
    required this.freq,
    required this.pos,
  });

  factory IndexEntry.fromJson(Map<String, dynamic> json) {
    // print('from json ${jsonEncode(json)}');
    return IndexEntry(
      docID: int.parse("${json['docID']}"),
      freq: int.parse("${json['freq']}"),
      pos: (json['pos'] as List<dynamic>).map((e) => int.parse("$e")).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docID': docID,
      'freq': freq,
      'pos': pos,
    };
  }
}

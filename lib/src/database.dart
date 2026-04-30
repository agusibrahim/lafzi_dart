/// SQLite database layer for Lafzi search.
///
/// Supports both compressed and uncompressed databases.
/// Compressed DB stores postings and posmaps as gzip BLOBs for ~50% size reduction.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';

/// A matched Quran verse with search metadata.
class QuranVerse {
  final int id;
  final int surahNo;
  final String surahName;
  final int ayatNo;
  final String textArabic;
  final String textIndonesian;
  final String? muqathaatText;
  final List<int> highlightPositions;
  final double score;
  final String? textHilight;

  QuranVerse({
    required this.id,
    required this.surahNo,
    required this.surahName,
    required this.ayatNo,
    required this.textArabic,
    required this.textIndonesian,
    this.muqathaatText,
    required this.highlightPositions,
    required this.score,
    this.textHilight,
  });

  Map<String, dynamic> toJson() => {
        'surah': surahNo,
        'name': surahName,
        'ayat': ayatNo,
        'text': textArabic,
        'trans': textIndonesian,
        'score': score,
        'highlightPos': highlightPositions,
        if (textHilight != null) 'text_hilight': textHilight,
      };

  @override
  String toString() =>
      '[$surahNo:$surahName:$ayatNo] score=${score.toStringAsFixed(2)}';
}

/// Trigram index entry from database.
class TrigramEntry {
  final String term;
  /// docID (1-based) -> list of positions
  final Map<int, List<int>> postings;

  TrigramEntry(this.term, this.postings);
}

// --- Compression helpers ---

/// Compresses a string to gzip bytes.
Uint8List compressString(String data) {
  return Uint8List.fromList(gzip.encode(utf8.encode(data)));
}

/// Decompresses gzip bytes back to a string.
String decompressToString(Uint8List data) {
  return utf8.decode(gzip.decode(data));
}

// --- Database ---

/// Database wrapper for Lafzi search.
class LafziDatabase {
  Database? _db;
  final String _dbPath;
  final bool _ownConnection;
  late final bool _compressed;

  LafziDatabase._(this._dbPath, this._db, this._ownConnection);

  /// Opens a database from file path.
  /// Automatically detects if the DB uses compressed BLOBs.
  static Future<LafziDatabase> open(String path) async {
    final db = sqlite3.open(path);
    final instance = LafziDatabase._(path, db, true);
    instance._detectFormat();
    return instance;
  }

  /// Wraps an existing sqlite3 Database connection.
  static LafziDatabase wrap(Database db) {
    final instance = LafziDatabase._('', db, false);
    instance._detectFormat();
    return instance;
  }

  Database get db => _db!;

  /// Whether this DB uses compressed BLOB storage.
  bool get isCompressed => _compressed;

  void _detectFormat() {
    // Check column type: if post column is BLOB, it's compressed
    final row = db.select('SELECT typeof(post) as t FROM vocal_index LIMIT 1');
    if (row.isNotEmpty) {
      _compressed = (row.first['t'] as String) == 'blob';
    } else {
      _compressed = false;
    }
  }

  /// Fetches a verse by 1-based ID.
  Map<String, dynamic>? getVerse(int id) {
    final row = db.select(
      'SELECT _id, surah_no, surah_name, ayat_no, ayat_arabic, '
      'ayat_indonesian, ayat_muqathaat, vocal_mapping_position, '
      'nonvocal_mapping_position FROM ayat_quran WHERE _id = ?',
      [id],
    );
    if (row.isEmpty) return null;
    return _parseVerseRow(row.first);
  }

  /// Fetches multiple verses by IDs in one query.
  List<Map<String, dynamic>> getVerses(List<int> ids) {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = db.select(
      'SELECT _id, surah_no, surah_name, ayat_no, ayat_arabic, '
      'ayat_indonesian, ayat_muqathaat, vocal_mapping_position, '
      'nonvocal_mapping_position FROM ayat_quran '
      'WHERE _id IN ($placeholders)',
      ids,
    );
    return rows.map(_parseVerseRow).toList();
  }

  Map<String, dynamic> _parseVerseRow(Row r) {
    return <String, dynamic>{
      'id': r['_id'] as int,
      'surah_no': r['surah_no'] as int,
      'surah_name': r['surah_name'] as String,
      'ayat_no': r['ayat_no'] as int,
      'ayat_arabic': r['ayat_arabic'] as String,
      'ayat_indonesian': r['ayat_indonesian'] as String,
      'muqathaat': r['ayat_muqathaat'] as String?,
      'vocal_posmap': _decodePosmap(r['vocal_mapping_position']),
      'nonvocal_posmap': _decodePosmap(r['nonvocal_mapping_position']),
    };
  }

  String? _decodePosmap(dynamic value) {
    if (value == null) return null;
    if (_compressed && value is Uint8List) {
      return decompressToString(value);
    }
    return value as String;
  }

  /// Looks up trigram postings from the index table.
  /// [mode] is 'v' (vocal) or 'nv' (nonvocal).
  Map<String, TrigramEntry> lookupTrigrams(
    Iterable<String> trigrams,
    String mode,
  ) {
    if (trigrams.isEmpty) return {};
    final table = mode == 'v' ? 'vocal_index' : 'nonvocal_index';
    final placeholders = List.filled(trigrams.length, '?').join(',');
    final rows = db.select(
      'SELECT term, post FROM $table WHERE term IN ($placeholders)',
      trigrams.toList(),
    );

    final result = <String, TrigramEntry>{};
    for (final r in rows) {
      final term = r['term'] as String;
      final String postJson;

      if (_compressed) {
        final blob = r['post'] as Uint8List;
        postJson = decompressToString(blob);
      } else {
        postJson = r['post'] as String;
      }

      final postMap = jsonDecode(postJson) as Map<String, dynamic>;
      final postings = <int, List<int>>{};
      for (final e in postMap.entries) {
        final docId = int.parse(e.key);
        final positions = (e.value as List)
            .map((v) => v is int ? v : int.parse(v as String))
            .toList();
        postings[docId] = positions;
      }
      result[term] = TrigramEntry(term, postings);
    }
    return result;
  }

  /// Closes the database if we own the connection.
  void close() {
    if (_ownConnection && _db != null) {
      _db!.dispose();
      _db = null;
    }
  }
}
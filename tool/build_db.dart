#!/usr/bin/env dart
/// Build lafzi.sqlite from uncompressed data files.
///
/// Usage:
///   dart run tool/build_db.dart <source_dir> <output_db> [--compress]
///
/// Flags:
///   --compress   Compress postings and posmaps with gzip (~50% smaller)
///
/// source_dir should contain:
///   - quran_teks.txt        (surah_no|surah_name|ayat_no|text)
///   - quran_trans_indonesian.txt (surah_no|ayat_no|translation)
///   - muqathaat.txt         (surah_no|surah_name|ayat_no|text)
///   - posmap_v.txt          (comma-separated positions, one per verse)
///   - posmap_nv.txt         (comma-separated positions, one per verse)
///   - index_v.jsn           (JSON trigram index for vocal mode)
///   - index_nv.jsn          (JSON trigram index for nonvocal mode)
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final compress = args.contains('--compress');
  final positional = args.where((a) => !a.startsWith('-')).toList();

  if (positional.length < 2) {
    stderr.writeln('Usage: dart run tool/build_db.dart <source_dir> <output_db> [--compress]');
    stderr.writeln('');
    stderr.writeln('  source_dir: directory with uncompressed lafzi data files');
    stderr.writeln('  output_db:  path for the output SQLite database');
    stderr.writeln('  --compress: gzip-compress postings & posmaps (~50% smaller)');
    exit(1);
  }

  final sourceDir = positional[0];
  final outputDb = positional[1];

  final dir = Directory(sourceDir);
  if (!dir.existsSync()) {
    stderr.writeln('Error: source directory not found: $sourceDir');
    exit(1);
  }

  final requiredFiles = [
    'quran_teks.txt',
    'quran_trans_indonesian.txt',
    'muqathaat.txt',
    'posmap_v.txt',
    'posmap_nv.txt',
    'index_v.jsn',
    'index_nv.jsn',
  ];

  for (final f in requiredFiles) {
    if (!File('$sourceDir/$f').existsSync()) {
      stderr.writeln('Error: required file not found: $sourceDir/$f');
      exit(1);
    }
  }

  final outputFile = File(outputDb);
  if (outputFile.existsSync()) outputFile.deleteSync();

  final mode = compress ? 'compressed' : 'uncompressed';
  print('Building lafzi.sqlite ($mode)...');
  final sw = Stopwatch()..start();

  final db = sqlite3.open(outputDb);

  try {
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA synchronous = OFF');
    db.execute('PRAGMA cache_size = -64000');

    _createTables(db, compress);
    _importQuranText(db, sourceDir);
    _importTranslations(db, sourceDir);
    _importMuqathaat(db, sourceDir);
    _importPosmaps(db, sourceDir, compress);
    _importTrigramIndex(db, '$sourceDir/index_v.jsn', 'vocal_index', compress);
    _importTrigramIndex(db, '$sourceDir/index_nv.jsn', 'nonvocal_index', compress);
    _createIndexes(db);

    db.execute('PRAGMA journal_mode = DELETE');
    db.execute('VACUUM');

    sw.stop();
    final size = outputFile.lengthSync();
    print('Done in ${sw.elapsedMilliseconds}ms');
    print('Database size: ${(size / 1024 / 1024).toStringAsFixed(1)} MB');
    print('Output: $outputDb');
  } catch (e, st) {
    stderr.writeln('Error: $e');
    stderr.writeln(st);
    exit(1);
  } finally {
    db.dispose();
  }
}

void _createTables(Database db, bool compress) {
  print('  Creating tables...');

  final posmapType = compress ? 'BLOB' : 'TEXT';
  final postType = compress ? 'BLOB' : 'TEXT';

  db.execute('''
    CREATE TABLE IF NOT EXISTS ayat_quran (
      _id INTEGER PRIMARY KEY AUTOINCREMENT,
      surah_no INTEGER NOT NULL,
      surah_name TEXT NOT NULL,
      ayat_no INTEGER NOT NULL,
      ayat_arabic TEXT NOT NULL,
      ayat_indonesian TEXT DEFAULT '',
      ayat_muqathaat TEXT DEFAULT '',
      vocal_mapping_position $posmapType DEFAULT '',
      nonvocal_mapping_position $posmapType DEFAULT ''
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS vocal_index (
      _id INTEGER PRIMARY KEY AUTOINCREMENT,
      term TEXT NOT NULL,
      post $postType NOT NULL
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS nonvocal_index (
      _id INTEGER PRIMARY KEY AUTOINCREMENT,
      term TEXT NOT NULL,
      post $postType NOT NULL
    )
  ''');
}

void _importQuranText(Database db, String sourceDir) {
  print('  Importing quran text...');
  final lines = File('$sourceDir/quran_teks.txt').readAsLinesSync();
  final stmt = db.prepare(
    'INSERT INTO ayat_quran (surah_no, surah_name, ayat_no, ayat_arabic) VALUES (?, ?, ?, ?)',
  );

  db.execute('BEGIN TRANSACTION');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final parts = line.split('|');
    if (parts.length < 4) continue;
    stmt.execute([int.parse(parts[0]), parts[1], int.parse(parts[2]), parts[3]]);
  }
  db.execute('COMMIT');
  stmt.dispose();
  print('    ${lines.where((l) => l.trim().isNotEmpty).length} verses');
}

void _importTranslations(Database db, String sourceDir) {
  print('  Importing translations...');
  final lines = File('$sourceDir/quran_trans_indonesian.txt').readAsLinesSync();
  final stmt = db.prepare(
    'UPDATE ayat_quran SET ayat_indonesian = ? WHERE surah_no = ? AND ayat_no = ?',
  );

  db.execute('BEGIN TRANSACTION');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final parts = line.split('|');
    if (parts.length < 3) continue;
    stmt.execute([parts[2], int.parse(parts[0]), int.parse(parts[1])]);
  }
  db.execute('COMMIT');
  stmt.dispose();
  print('    ${lines.where((l) => l.trim().isNotEmpty).length} translations');
}

void _importMuqathaat(Database db, String sourceDir) {
  print('  Importing muqathaat...');
  final lines = File('$sourceDir/muqathaat.txt').readAsLinesSync();
  final stmt = db.prepare(
    'UPDATE ayat_quran SET ayat_muqathaat = ? WHERE surah_no = ? AND ayat_no = ?',
  );

  db.execute('BEGIN TRANSACTION');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final parts = line.split('|');
    if (parts.length < 4) continue;
    stmt.execute([parts[3], int.parse(parts[0]), int.parse(parts[2])]);
  }
  db.execute('COMMIT');
  stmt.dispose();
  print('    ${lines.where((l) => l.trim().isNotEmpty).length} muqathaat entries');
}

void _importPosmaps(Database db, String sourceDir, bool compress) {
  print('  Importing position maps...');
  _importPosmapFile(db, '$sourceDir/posmap_v.txt', 'vocal_mapping_position', compress);
  _importPosmapFile(db, '$sourceDir/posmap_nv.txt', 'nonvocal_mapping_position', compress);
}

void _importPosmapFile(Database db, String path, String column, bool compress) {
  final lines = File(path).readAsLinesSync();
  final stmt = db.prepare('UPDATE ayat_quran SET $column = ? WHERE _id = ?');

  db.execute('BEGIN TRANSACTION');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    final value = compress ? _gzipBytes(lines[i]) : lines[i];
    stmt.execute([value, i + 1]);
  }
  db.execute('COMMIT');
  stmt.dispose();
  print('    $column: ${lines.where((l) => l.trim().isNotEmpty).length} entries');
}

void _importTrigramIndex(Database db, String jsonPath, String table, bool compress) {
  print('  Importing $table...');
  final content = File(jsonPath).readAsStringSync();
  final Map<String, dynamic> index = jsonDecode(content);

  final stmt = db.prepare('INSERT INTO $table (term, post) VALUES (?, ?)');

  db.execute('BEGIN TRANSACTION');
  var count = 0;
  for (final entry in index.entries) {
    final term = entry.key;
    final rawPostings = entry.value as List<dynamic>;

    final postings = <String, List<int>>{};
    for (final raw in rawPostings) {
      final m = raw as Map<String, dynamic>;
      final docId = m['docID'] as String;
      final pos = (m['pos'] as List)
          .map((e) => e is int ? e : int.parse(e as String))
          .toList();
      postings[docId] = pos;
    }

    final json = jsonEncode(postings);
    final value = compress ? _gzipBytes(json) : json;
    stmt.execute([term, value]);
    count++;
  }
  db.execute('COMMIT');
  stmt.dispose();
  print('    $count trigrams');
}

void _createIndexes(Database db) {
  print('  Creating indexes...');
  db.execute('CREATE INDEX IF NOT EXISTS idx_vocal_term ON vocal_index(term)');
  db.execute('CREATE INDEX IF NOT EXISTS idx_nonvocal_term ON nonvocal_index(term)');
  db.execute('CREATE INDEX IF NOT EXISTS idx_ayat_surah ON ayat_quran(surah_no, ayat_no)');
  print('    Done');
}

Uint8List _gzipBytes(String data) {
  return Uint8List.fromList(gzip.encode(utf8.encode(data)));
}
#!/usr/bin/env dart
/// CLI example for lafzi_dart.
///
/// Usage:
///   dart run example/cli_search.dart <db_path> <query> [mode] [threshold]
///
/// Examples:
///   dart run example/cli_search.dart data/lafzi.sqlite "kunfayakun"
///   dart run example/cli_search.dart data/lafzi.sqlite "bismillah" v 0.8
library;

import 'dart:io';
import 'package:lafzi_dart/lafzi_dart.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run example/cli_search.dart <db_path> <query> [mode] [threshold]');
    stderr.writeln('');
    stderr.writeln('  db_path    : path to lafzi.sqlite');
    stderr.writeln('  query      : search query in Latin transliteration');
    stderr.writeln('  mode       : "v" (vocal) or "nv" (nonvocal), default: v');
    stderr.writeln('  threshold  : 0.3 - 0.95, default: 0.95');
    exit(1);
  }

  final dbPath = args[0];
  final query = args.length > 1 ? args[1] : 'kunfayakun';
  final mode = args.length > 2 ? args[2] : 'v';
  final threshold = args.length > 3 ? double.tryParse(args[3]) ?? 0.95 : 0.95;

  if (!File(dbPath).existsSync()) {
    stderr.writeln('Error: database not found: $dbPath');
    stderr.writeln('Run "dart run tool/build_db.dart <source_dir> data/lafzi.sqlite" first.');
    exit(1);
  }

  final db = await LafziDatabase.open(dbPath);

  try {
    print('Searching for "$query" (mode=$mode, threshold=$threshold)...');
    print('');

    final sw = Stopwatch()..start();
    final results = await search(
      db,
      query,
      options: SearchOptions(
        mode: mode,
        threshold: threshold,
        isHilight: false,
      ),
    );
    sw.stop();

    if (results.isEmpty) {
      print('No results found.');
    } else {
      for (final v in results) {
        print('${v.surahName} ${v.ayatNo} (score: ${v.score.toStringAsFixed(2)})');
        print('  ${v.textArabic}');
        print('  ${v.textIndonesian}');
        print('');
      }
    }

    print('${results.length} result(s) in ${sw.elapsedMilliseconds}ms');
  } finally {
    db.close();
  }
}
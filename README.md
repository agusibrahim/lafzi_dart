# Lafzi Dart

Lafzi Dart is a Dart library for searching Quranic verses using fuzzy matching and highlighting. It automatically downloads and caches the compressed data files needed for searching, and can optionally load the full verse text and Indonesian translation.

This project is a Dart port of the original JavaScript project: [lafzi.js](https://github.com/lafzi/lafzi.js).

Credit to [skipness/lzstring-dart](https://github.com/skipness/lzstring-dart) for the Dart implementation of the lz-string compression algorithm used in this project.

Uncompressed data can be found in the original project's repository: [lafzi.js/.uncompressed_data](https://github.com/lafzi/lafzi.js/tree/master/.uncompressed_data).

## Features

- Fuzzy search for Quranic verses.
- Highlight matched text.
- Returns verse details: surah name, ayat number, text, translation, score, and highlight positions.
- Automatically downloads and caches required `.lz` data files.
- Optional loading of Quran text and Indonesian translation.
- Progress callback to report download and decompression steps.
- No Flutter dependency; uses Dart IO for file access.
- Pluggable `LafziFileLoader` for custom data sources (e.g. Flutter assets).

## Installation

Add to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  lafzi_dart: <version>
```

## Usage

Example usage in a Dart console app:

```dart
import 'package:lafzi_dart/lafzi_dart.dart';

void main() async {
  final lafziSearch = LafziSearch();

  final result = await lafziSearch.searchLafzi(
    query: 'sibgo',
    mode: 'v',
    threshold: 0.95,
    loadQuranText: true,
    loadTranslation: true,
    onProcess: (msg) => print(msg),
  );

  for (final verse in result) {
    print('Surah: ${verse.name}, Ayat: ${verse.ayat}');
    print('Text: ${verse.text}');
    print('Translation: ${verse.trans}');
    if (verse.textHilight != null) {
      print('Highlighted Text: ${verse.textHilight}');
    }
    print('Score: ${verse.score?.toStringAsFixed(4)}');
    print('Highlight Positions: ${verse.highlightPos}');
  }
}
```

`loadQuranText` and `loadTranslation` control whether the verse text and Indonesian translation are downloaded and included in the results. If omitted, the fields will be empty. The optional `onProcess` callback provides messages about download and decompression progress. Data is cached in the system temporary directory by default; pass a custom `cacheDir` to `searchLafzi` to change the cache location.

## Custom File Loading

By default, `LafziSearch` downloads the required `.lz` data files from the GitHub release and caches them locally. In environments without network access or when bundling the data with your application, implement `LafziFileLoader` and pass it to `LafziSearch`.

- **`DartFileLoader`**: Load files from the local file system in a pure Dart application.

  ```dart
  import 'dart:io';
  import 'dart:typed_data';
  import 'package:lafzi_dart/src/loaddata.dart';

  class DartFileLoader implements LafziFileLoader {
    @override
    Future<Uint8List> load(String path) => File('data/$path').readAsBytes();
  }

  final lafziSearch = LafziSearch(lafziLoader: DartFileLoader());
  ```

- **`FlutterFileLoader`**: Load files from Flutter assets.

```dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lafzi_dart/src/loaddata.dart';

class FlutterFileLoader implements LafziFileLoader {
  @override
  Future<Uint8List> load(String path) async {
    final data = await rootBundle.load('assets/data/$path');
    return data.buffer.asUint8List();
  }
}

final lafziSearch = LafziSearch(lafziLoader: FlutterFileLoader());
```

Remember to copy the `.lz` files (from the `data/` directory) into your application's assets and declare them in `pubspec.yaml`.

## Data Files

The following compressed `.lz` files are used by the library and are downloaded automatically when needed:

- `muqathaat.lz`
- `index_v.lz`
- `index_nv.lz`
- `posmap_v.lz`
- `posmap_nv.lz`
- `quran_teks.lz`
- `quran_trans_indonesian.lz`

If you provide a custom `LafziFileLoader`, ensure these files are available in your chosen location.

## How It Works

- The library downloads compressed data files on demand and caches them.
- Files are decompressed and parsed for fast search and retrieval.
- The `searchLafzi` method performs fuzzy matching and returns a list of matching verses.

## License

MIT License

# Lafzi Dart

Lafzi Dart is a Dart library for searching Quranic verses using fuzzy matching and highlighting. It supports searching with various modes and provides verse details including translation and highlight positions.

This project is a Dart port of the original JavaScript project: [lafzi.js](https://github.com/lafzi/lafzi.js).

Credit to [skipness/lzstring-dart](https://github.com/skipness/lzstring-dart) for the Dart implementation of the lz-string compression algorithm used in this project.

Uncompressed data can be found in the original project's repository: [lafzi.js/.uncompressed_data](https://github.com/lafzi/lafzi.js/tree/master/.uncompressed_data).

## Features

- Fuzzy search for Quranic verses
- Highlight matched text
- Returns verse details: surah name, ayat number, text, translation, score, and highlight positions
- No Flutter dependency; uses Dart IO for file access

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
import 'package:lafzi_dart/src/models.dart';

void main() async {
  final lafziSearch = LafziSearch();

  try {
    final List<QuranVerse> result = await lafziSearch.searchLafzi(
      mode: "v",
      threshold: 0.95,
      isHilight: true,
      query: "sibgo",
      multipleHighlightPos: false,
    );

    if (result.isNotEmpty) {
      print("Search Results for 'sibgo':");
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
    } else {
      print("No results found for 'sibgo'.");
    }
  } catch (e) {
    print("Error during search: $e");
  }
}
```

## Custom File Loading

The `LafziSearch` class requires an implementation of `LafziFileLoader` to load the necessary data files. This allows flexibility for different environments (e.g., pure Dart applications or Flutter applications).

- **`DartFileLoader`**: For pure Dart applications (like console apps), you can use `DartFileLoader` which utilizes `dart:io` to read files from the file system.

  ```dart
  import 'dart:io';
  import 'dart:typed_data';
  import 'package:lafzi_dart/src/loaddata.dart';

  class DartFileLoader implements LafziFileLoader {
    @override
    Future<Uint8List> load(String path) {
      final file = File(path);
      return file.readAsBytes();
    }
  }

  // Initialize LafziSearch with DartFileLoader
  final lafziSearch = LafziSearch(lafziLoader: DartFileLoader());
  ```

- **`FlutterFileLoader`**: For Flutter applications, you would typically load assets using `rootBundle`. An example `FlutterFileLoader` implementation would look like this (you'll need to uncomment and adapt this in your Flutter project):

  ```dart
import 'package:flutter/services.dart' show rootBundle; Add this import
import 'dart:typed_data';
import 'package:lafzi_dart/src/loaddata.dart';

class FlutterFileLoader implements LafziFileLoader {
  @override
  Future<Uint8List> load(String path) async {
    /* Make sure to add your data files to your pubspec.yaml under assets:
    assets:
      - assets/data/ 
    */
    final ByteData data = await rootBundle.load('assets/data/$path');
    return data.buffer.asUint8List();
  }
}

Initialize LafziSearch with FlutterFileLoader
final lafziSearch = LafziSearch(lafziLoader: FlutterFileLoader());
  ```
  Remember to copy all data files (from the `data/` directory) to your Flutter project's `assets/data/` folder and declare them in your `pubspec.yaml` under the `assets` section.

## Data Files

Make sure the required data files are present in the `data/` directory:

- `muqathaat.lz`
- `index_v.lz`
- `index_nv.lz`
- `posmap_v.lz`
- `posmap_nv.lz`
- `quran_teks.lz`
- `quran_trans_indonesian.lz`

## How It Works

- The library loads compressed data files using Dart IO.
- It decompresses and parses the data for fast search and retrieval.
- The `searchLafzi` method performs fuzzy matching and returns a list of matching verses.

## License

MIT License
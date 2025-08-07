# Lafzi Dart

Lafzi Dart is a Dart library for searching Quranic verses using fuzzy matching and highlighting. It supports searching with various modes and provides verse details including translation and highlight positions.

## Features

- Fuzzy search for Quranic verses
- Highlight matched text
- Returns verse details: surah name, ayat number, text, translation, score, and highlight positions
- No Flutter dependency; uses Dart IO for file access

## Installation

Add to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  lafzi_dart: 0.1.0
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
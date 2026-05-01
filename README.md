# lafzi_dart

[![pub package](https://img.shields.io/pub/v/lafzi_dart.svg)](https://pub.dev/packages/lafzi_dart)

Al-Quran phonetic search engine for Dart & Flutter. Search Quran verses by Latin transliteration (e.g. "kunfayakun", "bismillah") using trigram indexing and phonetic matching.

Pure Dart — no Flutter dependency required. Works as a standalone Dart package.

Ported from [lafzi.js](https://github.com/lafzi/lafzi.js) with SQLite backend for fast, efficient search.

## Features

- Phonetic search with Latin transliteration input
- Two modes: **vocal** (with harakat) and **nonvocal** (consonants only)
- Configurable match threshold (0.3 - 0.95)
- Text highlighting of matched regions
- SQLite backend — fast, 50ms per query
- Optional gzip compression for database (~45% smaller)
- Pure Dart, works standalone and in Flutter

## Installation

```yaml
dependencies:
  lafzi_dart: ^1.0.0
```

## Database

You need a `lafzi.sqlite` database file. Either:

1. **Download pre-built** from [GitHub Releases](https://github.com/agusibrahim/lafzi_dart/releases)
2. **Build from source** using the included tool:
   ```bash
   dart run tool/build_db.dart <source_dir> data/lafzi.sqlite
   dart run tool/build_db.dart <source_dir> data/lafzi_compressed.sqlite --compress
   ```

Source data files are from [lafzi.js/.uncompressed_data](https://github.com/lafzi/lafzi.js/tree/master/.uncompressed_data).

## Usage

```dart
import 'package:lafzi_dart/lafzi_dart.dart';

final db = await LafziDatabase.open('path/to/lafzi_compressed.sqlite');

final results = await search(
  db,
  'kunfayakun',
  options: SearchOptions(
    mode: 'v',          // 'v' = vocal, 'nv' = nonvocal
    threshold: 0.95,    // 0.3 - 0.95
    isHilight: true,    // generate highlighted text
  ),
);

for (final verse in results) {
  print('${verse.surahName} ${verse.ayatNo}');
  print('  ${verse.textArabic}');
  print('  ${verse.textIndonesian}');
  print('  Score: ${verse.score}');
}

db.close();
```

### Phonetic Conversion Only

No database needed for phonetic conversion:

```dart
import 'package:lafzi_dart/lafzi_dart.dart';

print(convert('bismillah'));        // BISMILAH
print(convertNoVowel('bismillah')); // BSMLH
print(convert('alhamdulillah'));    // XALHAMDULILAH
```

## Search Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `mode` | `String` | `'v'` | `'v'` = with vowels, `'nv'` = consonants only |
| `threshold` | `double` | `0.95` | Match threshold (0.3 - 0.95). Lower = more results |
| `isHilight` | `bool` | `true` | Generate `<span>` highlighted text |
| `multipleHighlightPos` | `bool` | `false` | Return all highlight spans |

## QuranVerse Fields

| Field | Type | Description |
|-------|------|-------------|
| `surahNo` | `int` | Surah number (1-114) |
| `surahName` | `String` | Surah name |
| `ayatNo` | `int` | Verse number |
| `textArabic` | `String` | Arabic text |
| `textIndonesian` | `String` | Indonesian translation |
| `score` | `double` | Match score (higher = better) |
| `highlightPositions` | `List<int>` | Highlight positions |
| `textHilight` | `String?` | HTML-highlighted text |
| `muqathaatText` | `String?` | Muqathaat text (if applicable) |

## Compressed Database

Use `--compress` flag to build a smaller database:

```
Uncompressed: 14.3 MB
Compressed:    7.9 MB (-45%)

Search overhead: ~6-13ms per query
```

The library auto-detects compressed vs uncompressed databases.

## Flutter Example

See `example/flutter_example/` for a complete Flutter app with:
- Async database download with progress indicator
- Cached database (downloads only once)
- Non-blocking search
- Vocal/nonvocal mode toggle
- Adjustable threshold

```bash
cd example/flutter_example
flutter pub get
flutter run
```

## CLI Example

```bash
# From repo root
dart run example/cli_search.dart data/lafzi.sqlite "kunfayakun"
dart run example/cli_search.dart data/lafzi.sqlite "bismillah" v 0.8
dart run example/cli_search.dart data/lafzi.sqlite "alhamdulillah" nv 0.7
```

## Project Structure

```
lafzi_dart/
├── lib/
│   ├── lafzi_dart.dart        # Public API
│   └── src/
│       ├── phonetics.dart      # Phonetic conversion
│       ├── trigram.dart        # Trigram extraction
│       ├── array.dart          # LCS, contiguity, highlight span
│       ├── database.dart       # SQLite layer + QuranVerse
│       ├── searcher.dart       # Search pipeline
│       └── hilight.dart        # Text highlighting
├── tool/
│   └── build_db.dart           # Build SQLite from source data
├── example/
│   ├── cli_search.dart         # Dart CLI example
│   └── flutter_example/        # Flutter app example
└── test/
    └── lafzi_test.dart         # Unit + integration tests
```

## Credit

- Original algorithm: [lafzi.js](https://github.com/lafzi/lafzi.js) by [Sigit Prabowo](https://github.com/sprabowo)

## License

MIT License
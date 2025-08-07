import 'dart:io';
import 'dart:typed_data';

import 'package:lafzi_dart/lafzi_dart.dart';
import 'package:lafzi_dart/src/loaddata.dart';
import 'package:lafzi_dart/src/models.dart'; // Import models if you need to access QuranVerse properties

class DartFileLoader implements LafziFileLoader {
  @override
  Future<Uint8List> load(String path) {
    final file = File(path);
    return file.readAsBytes();
  }
}
// Use this if you are using flutter. Make sure you copy all files in the data folder to flutter assets.
// class FlutterFileLoader implements LafziFileLoader {
//   @override
//   Future<Uint8List> load(String path) async {
//     final ByteData data = await rootBundle.load('assets/$path');
//     return data.buffer.asUint8List();
//   }
// }
void main() async {
  final lafziSearch = LafziSearch(lafziLoader: DartFileLoader());

  try {
    final List<QuranVerse> result = await lafziSearch.searchLafzi(
      mode: "v",
      threshold: 0.95,
      isHilight: true,
      query: "sibgo",
      multipleHighlightPos: false,
    );

    if (result.isNotEmpty) {
      print("Search Results for 'sibgatallah':");
      for (final verse in result) {
        print('---\n');
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

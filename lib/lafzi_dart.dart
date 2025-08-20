import 'dart:io';
import 'package:lafzi_dart/src/loaddata.dart';
import 'package:lafzi_dart/src/data_parser.dart';
import 'package:lafzi_dart/src/searcher.dart';
import 'package:lafzi_dart/src/models.dart';
import 'package:lafzi_dart/src/quran_stub.dart';

class LafziSearch {
  late Map<String, Map<String, List<IndexEntry>>> _dataIndex;
  late Map<String, List<List<int>>> _dataPosmap;
  late List<QuranVerse> _dataQuran;
  late Map<int, Map<int, String>> _dataMuqathaat;

  bool _isDataLoaded = false;
  bool _textLoaded = false;
  bool _translationLoaded = false;
  LafziFileLoader? lafziLoader;
  LafziSearch({this.lafziLoader});

  Future<void> _parseData({
    bool loadQuranText = false,
    bool loadTranslation = false,
    void Function(String message)? onProgress,
    Directory? cacheDir,
  }) async {
    final needsText = loadQuranText && !_textLoaded;
    final needsTrans = loadTranslation && !_translationLoaded;
    if (_isDataLoaded && !needsText && !needsTrans) return;

    final buffer = await loadData(
      loader: lafziLoader,
      loadQuranText: needsText,
      loadTranslation: needsTrans,
      onProgress: onProgress,
      cacheDir: cacheDir,
    );

    if (!_isDataLoaded) {
      _dataMuqathaat = parseMuqathaat(buffer['muqathaat']!);
      _dataPosmap = {
        'nv': parsePosmap(buffer['posmap_nv']!),
        'v': parsePosmap(buffer['posmap_v']!),
      };
      _dataIndex = {
        'nv': parseIndex(buffer['index_nv']!),
        'v': parseIndex(buffer['index_v']!),
      };
      _dataQuran = generateEmptyQuran();
      _isDataLoaded = true;
    }

    if (buffer.containsKey('quran_teks')) {
      final oldTrans = _dataQuran.isNotEmpty
          ? _dataQuran.map((e) => e.trans).toList()
          : null;
      _dataQuran = parseQuran(buffer['quran_teks']!,
          buffer['quran_trans_indonesian']);
      if (oldTrans != null) {
        for (int i = 0; i < oldTrans.length && i < _dataQuran.length; i++) {
          _dataQuran[i] = _dataQuran[i].copyWith(trans: oldTrans[i]);
        }
      }
      _textLoaded = true;
      if (buffer.containsKey('quran_trans_indonesian')) {
        _translationLoaded = true;
      }
    } else if (buffer.containsKey('quran_trans_indonesian')) {
      updateQuranTranslation(_dataQuran, buffer['quran_trans_indonesian']!);
      _translationLoaded = true;
    }
  }

  double _optimizedThreshold(double t) {
    final tmpT = double.parse((t * 10).toStringAsFixed(2));
    if ((tmpT - 1).abs() > 0.001) { // Using a small epsilon for float comparison
      return (tmpT - 1) / 10;
    }
    return t;
  }

  String? _checkQuery(String? query) {
    if (query != null) {
      return Uri.decodeComponent(query.trim()).replaceAll(RegExp(r'[-+]'), ' ');
    }
    return null;
  }

  Future<List<QuranVerse>> searchLafzi({
    String mode = 'v',
    double threshold = 0.95,
    bool isHilight = true,
    String? query,
    bool multipleHighlightPos = false,
    bool loadQuranText = false,
    bool loadTranslation = false,
    void Function(String message)? onProcess,
    Directory? cacheDir,
  }) async {
    query = _checkQuery(query);
    if (query == null) {
      return [];
    }

    await _parseData(
      loadQuranText: loadQuranText,
      loadTranslation: loadTranslation,
      onProgress: onProcess,
      cacheDir: cacheDir,
    ); // Ensure data is loaded

    List<LafziDocument> searched = await search(
      _dataIndex[mode]!,
      query,
      threshold,
      mode,
    );
    double oldThreshold = threshold;

    if (searched.isEmpty && (oldThreshold - threshold).abs() < 0.001) {
      // first relaxation attempt
      threshold = _optimizedThreshold(threshold);
      searched = await search(
        _dataIndex[mode]!,
        query,
        threshold,
        mode,
      );
      oldThreshold = threshold;
    }
    if (searched.isEmpty && (oldThreshold - threshold).abs() < 0.001) {
      // second relaxation attempt with updated baseline
      threshold = _optimizedThreshold(threshold);
      searched = await search(
        _dataIndex[mode]!,
        query,
        threshold,
        mode,
      );
    }

    List<LafziDocument> ranked = await rank(
      searched,
      _dataPosmap[mode]!,
      _dataQuran,
      multipleHighlightPos: multipleHighlightPos,
    );

    List<QuranVerse> result = await prepare(
      ranked,
      _dataQuran,
      muqathaatData: _dataMuqathaat,
      isHilight: isHilight,
      multipleHighlightPos: multipleHighlightPos,
    );

    return result;
  }
}

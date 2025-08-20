import 'package:lafzi_dart/src/loaddata.dart';
import 'package:lafzi_dart/src/data_parser.dart';
import 'package:lafzi_dart/src/searcher.dart';
import 'package:lafzi_dart/src/models.dart';

class LafziSearch {
  late Map<String, Map<String, List<IndexEntry>>> _dataIndex;
  late Map<String, List<List<int>>> _dataPosmap;
  late List<QuranVerse> _dataQuran;
  late Map<int, Map<int, String>> _dataMuqathaat;

  bool _isDataLoaded = false;
  LafziFileLoader? lafziLoader;
  LafziSearch({this.lafziLoader});

  Future<void> _parseData() async {
    if (_isDataLoaded) return;

    final buffer = await loadData(loader: lafziLoader);

    _dataMuqathaat = parseMuqathaat(buffer['muqathaat']!);
    _dataQuran = parseQuran(
      buffer['quran_teks']!,
      buffer['quran_trans_indonesian']!,
    );
    _dataPosmap = {};
    _dataPosmap['nv'] = parsePosmap(buffer['posmap_nv']!);
    _dataPosmap['v'] = parsePosmap(buffer['posmap_v']!);
    _dataIndex = {};
    _dataIndex['nv'] = parseIndex(buffer['index_nv']!);
    _dataIndex['v'] = parseIndex(buffer['index_v']!);

    _isDataLoaded = true;
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
  }) async {
    query = _checkQuery(query);
    if (query == null) {
      return [];
    }

    await _parseData(); // Ensure data is loaded

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

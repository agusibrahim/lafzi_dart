import 'dart:io';
import 'dart:typed_data';
import 'package:lafzi_dart/src/lzstring.dart';

/// Placeholder URLs for remote data. Replace with real direct URLs.
const String urlMuqathaat = 'https://example.com/muqathaat.lz';
const String urlIndexV = 'https://example.com/index_v.lz';
const String urlIndexNv = 'https://example.com/index_nv.lz';
const String urlPosmapV = 'https://example.com/posmap_v.lz';
const String urlPosmapNv = 'https://example.com/posmap_nv.lz';
const String urlQuranText = 'https://example.com/quran_teks.lz';
const String urlQuranTrans =
    'https://example.com/quran_trans_indonesian.lz';

class _DataFile {
  final String name;
  final String key;
  final String url;
  const _DataFile(this.name, this.key, this.url);
}

/// Downloads a file if it does not exist in cache and returns its bytes.
Future<Uint8List> _loadOrDownload(
  _DataFile file,
  Directory cacheDir,
  void Function(String message)? onProgress,
) async {
  final cached = File('${cacheDir.path}/${file.name}');
  if (await cached.exists()) {
    onProgress?.call('using cached ${file.name}');
    return await cached.readAsBytes();
  }

  onProgress?.call('downloading ${file.name}');
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(file.url));
  final response = await request.close();
  final bytes = await response.fold<BytesBuilder>(
      BytesBuilder(), (b, d) => b..add(d)).then((b) => b.takeBytes());
  await cached.writeAsBytes(bytes, flush: true);
  client.close();
  return Uint8List.fromList(bytes);
}

/// Loads required data files, downloading them on the fly if necessary.
///
/// [loadQuranText] and [loadTranslation] control whether the Quran text and
/// translation files are loaded in addition to the base index data.
/// [cacheDir] specifies where downloaded files are stored. Defaults to a
/// temporary directory.
Future<Map<String, String>> loadData({
  LafziFileLoader? loader,
  bool loadQuranText = false,
  bool loadTranslation = false,
  void Function(String message)? onProgress,
  Directory? cacheDir,
}) async {
  final buffer = <String, String>{};
  final dir = cacheDir ?? Directory('${Directory.systemTemp.path}/lafzi_cache');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final files = <_DataFile>[
    const _DataFile('muqathaat.lz', 'muqathaat', urlMuqathaat),
    const _DataFile('index_v.lz', 'index_v', urlIndexV),
    const _DataFile('index_nv.lz', 'index_nv', urlIndexNv),
    const _DataFile('posmap_v.lz', 'posmap_v', urlPosmapV),
    const _DataFile('posmap_nv.lz', 'posmap_nv', urlPosmapNv),
    if (loadQuranText) const _DataFile('quran_teks.lz', 'quran_teks', urlQuranText),
    if (loadTranslation)
      const _DataFile('quran_trans_indonesian.lz',
          'quran_trans_indonesian', urlQuranTrans),
  ];

  final results = await Future.wait(files.map((f) async {
    if (loader != null) {
      return await loader.load(f.name);
    }
    return await _loadOrDownload(f, dir, onProgress);
  }));

  for (int i = 0; i < files.length; i++) {
    buffer[files[i].key] =
        (await LZString.decompressFromUint8Array(results[i])) ?? '';
  }

  return buffer;
}

/// Interface for loading a file.
/// Implement this in your application (Dart CLI or Flutter)
/// and pass it to the library.
abstract class LafziFileLoader {
  Future<Uint8List> load(String path);
}

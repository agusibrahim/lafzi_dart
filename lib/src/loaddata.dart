import 'dart:io';
import 'dart:typed_data';
import 'package:lafzi_dart/src/lzstring.dart';

Future<Uint8List> _download(String url) async {
  final client = HttpClient()..followRedirects = true;
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
          'Failed to GET $url (status ${response.statusCode})');
    }
    final builder = BytesBuilder();
    await for (final data in response) {
      builder.add(data);
    }
    return builder.toBytes();
  } finally {
    client.close();
  }
}

Future<Map<String, String>> loadData({LafziFileLoader? loader}) async {
  const String urlMuqathaat =
      'https://github.com/agusibrahim/lafzi_dart/releases/download/v0.1.0/muqathaat.lz';
  const String urlIndexV =
      'https://github.com/agusibrahim/lafzi_dart/releases/download/v0.1.0/index_v.lz';
  const String urlIndexNv =
      'https://github.com/agusibrahim/lafzi_dart/releases/download/v0.1.0/index_nv.lz';
  const String urlPosmapV =
      'https://github.com/agusibrahim/lafzi_dart/releases/download/v0.1.0/posmap_v.lz';
  const String urlPosmapNv =
      'https://github.com/agusibrahim/lafzi_dart/releases/download/v0.1.0/posmap_nv.lz';
  const String urlQuranText =
      'https://github.com/agusibrahim/lafzi_dart/releases/download/v0.1.0/quran_teks.lz';
  const String urlQuranTrans =
      'https://github.com/agusibrahim/lafzi_dart/releases/download/v0.1.0/quran_trans_indonesian.lz';

  final urls = [
    urlMuqathaat,
    urlIndexV,
    urlIndexNv,
    urlPosmapV,
    urlPosmapNv,
    urlQuranText,
    urlQuranTrans,
  ];

  final results = await Future.wait(
    urls.map((url) => loader == null ? _download(url) : loader.load(url)),
  );

  final buffer = <String, String>{};
  buffer['muqathaat'] =
      (await LZString.decompressFromUint8Array(results[0])) ?? '';
  buffer['index_v'] =
      (await LZString.decompressFromUint8Array(results[1])) ?? '';
  buffer['index_nv'] =
      (await LZString.decompressFromUint8Array(results[2])) ?? '';
  buffer['posmap_v'] =
      (await LZString.decompressFromUint8Array(results[3])) ?? '';
  buffer['posmap_nv'] =
      (await LZString.decompressFromUint8Array(results[4])) ?? '';
  buffer['quran_teks'] =
      (await LZString.decompressFromUint8Array(results[5])) ?? '';
  buffer['quran_trans_indonesian'] =
      (await LZString.decompressFromUint8Array(results[6])) ?? '';

  return buffer;
}

/// Interface for loading a file.
/// Implement this in your application (Dart CLI or Flutter)
/// and pass it to the library.
abstract class LafziFileLoader {
  Future<Uint8List> load(String path);
}

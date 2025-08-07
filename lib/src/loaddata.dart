import 'dart:io';

import 'package:lafzi_dart/src/lzstring.dart';

Future<Map<String, String>> loadData() async {
  final buffer = <String, String>{};

  final files = [
    'data/muqathaat.lz',
    'data/index_v.lz',
    'data/index_nv.lz',
    'data/posmap_v.lz',
    'data/posmap_nv.lz',
    'data/quran_teks.lz',
    'data/quran_trans_indonesian.lz',
  ];

  final results = await Future.wait(
    files.map((path) => File(path).readAsBytes()),
  );

  buffer['muqathaat'] = (await LZString.decompressFromUint8Array(results[0]))??'';
  buffer['index_v'] = (await LZString.decompressFromUint8Array(results[1]))??'';
  buffer['index_nv'] = (await LZString.decompressFromUint8Array(results[2]))??'';
  buffer['posmap_v'] = (await LZString.decompressFromUint8Array(results[3]))??'';
  buffer['posmap_nv'] = (await LZString.decompressFromUint8Array(results[4]))??'';
  buffer['quran_teks'] = (await LZString.decompressFromUint8Array(results[5]))??'';
  buffer['quran_trans_indonesian'] = (await LZString.decompressFromUint8Array(results[6]))??'';

  return buffer;
}

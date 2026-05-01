import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lafzi_dart/lafzi_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

const _dbUrl =
    'https://github.com/agusibrahim/lafzi_dart/releases/download/v0.1.0/lafzi_compressed.sqlite';
const _dbFile = 'lafzi_compressed.sqlite';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lafzi Quran Search',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  List<QuranVerse> _results = [];
  bool _searching = false;
  String? _dbStatus;
  double _downloadProgress = 0;
  bool _dbReady = false;
  String _mode = 'v';
  double _threshold = 0.8;
  LafziDatabase? _db;
  String? _error;

  // Parse HTML highlight spans to TextSpans with yellow background
  Widget _buildHighlightedText(String textHilight) {
    final span = RegExp(r"<span class='hl_block'>(.*?)</span>");
    final matches = span.allMatches(textHilight).toList();

    if (matches.isEmpty) {
      return Text(
        textHilight,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontSize: 22,
          fontFamily: 'MeQuran',
          color: Colors.black87,
        ),
      );
    }

    final textSpans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Text before highlight
      if (match.start > lastEnd) {
        textSpans.add(TextSpan(
          text: textHilight.substring(lastEnd, match.start),
          style: const TextStyle(
            fontFamily: 'MeQuran',
            fontSize: 22,
            color: Colors.black87,
          ),
        ));
      }

      // Highlighted text
      final hlText = match.group(1) ?? '';
      textSpans.add(TextSpan(
        text: hlText,
        style: const TextStyle(
          fontFamily: 'MeQuran',
          fontSize: 22,
          color: Colors.black87,
          backgroundColor: Colors.yellow,
        ),
      ));

      lastEnd = match.end;
    }

    // Remaining text
    if (lastEnd < textHilight.length) {
      textSpans.add(TextSpan(
        text: textHilight.substring(lastEnd),
        style: const TextStyle(
          fontFamily: 'MeQuran',
          fontSize: 22,
          color: Colors.black87,
        ),
      ));
    }

    return RichText(
      textAlign: TextAlign.right,
      text: TextSpan(children: textSpans),
      textDirection: TextDirection.rtl,
    );
  }

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    try {
      // Load native SQLite library for Android/iOS
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = '${docDir.path}/$_dbFile';
      final file = File(dbPath);

      if (file.existsSync()) {
        setState(() => _dbStatus = 'Opening database...');
        _db = await LafziDatabase.open(dbPath);
        setState(() => _dbReady = true);
        return;
      }

      // Download database with redirect handling
      setState(() {
        _dbStatus = 'Downloading database...';
        _downloadProgress = 0;
      });

      final client = HttpClient();
      client.autoUncompress = false;
      client.connectionTimeout = const Duration(seconds: 30);

      HttpClientResponse? redirectResponse;
      String url = _dbUrl;

      // Follow redirects
      for (var i = 0; i < 5; i++) {
        final req = await client.getUrl(Uri.parse(url));
        redirectResponse = await req.close();
        final location = redirectResponse.headers.value('location');
        if (location != null &&
            (redirectResponse.statusCode == 301 ||
                redirectResponse.statusCode == 302 ||
                redirectResponse.statusCode == 307 ||
                redirectResponse.statusCode == 308)) {
          url = location;
          await redirectResponse.drain<void>();
          continue;
        }
        break;
      }

      final response = redirectResponse!;

      if (response.statusCode != 200) {
        await response.drain<void>();
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      final total = response.contentLength;
      final output = file.openWrite();
      var received = 0;

      await for (final chunk in response) {
        output.add(chunk);
        received += chunk.length;
        if (total > 0) {
          setState(() {
            _downloadProgress = received / total;
            _dbStatus =
                'Downloading... ${(received / 1024 / 1024).toStringAsFixed(1)} / ${(total / 1024 / 1024).toStringAsFixed(1)} MB';
          });
        }
      }

      await output.flush();
      await output.close();
      client.close();

      setState(() => _dbStatus = 'Opening database...');
      _db = await LafziDatabase.open(dbPath);
      setState(() => _dbReady = true);
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    }
  }

  Future<void> _doSearch() async {
    if (_db == null || _controller.text.trim().isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await search(
        _db!,
        _controller.text.trim(),
        options: SearchOptions(
          mode: _mode,
          threshold: _threshold,
          isHilight: true,
        ),
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Search error: $e';
        _searching = false;
      });
    }
  }

  @override
  void dispose() {
    _db?.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lafzi Quran Search'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Cari ayat... (e.g. kunfayakun, bismillah)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _dbReady && !_searching
                          ? _doSearch
                          : null,
                    ),
                  ),
                  onSubmitted: (_) =>
                      _dbReady && !_searching ? _doSearch() : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Mode:'),
                    const SizedBox(width: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'v', label: Text('Vocal')),
                        ButtonSegment(value: 'nv', label: Text('Nonvocal')),
                      ],
                      selected: {_mode},
                      onSelectionChanged: _dbReady
                          ? (v) => setState(() => _mode = v.first)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    const Text('Threshold:'),
                    Expanded(
                      child: Slider(
                        value: _threshold,
                        min: 0.3,
                        max: 0.95,
                        divisions: 13,
                        label: _threshold.toStringAsFixed(2),
                        onChanged: (v) => setState(() => _threshold = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (!_dbReady)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(_dbStatus ?? 'Loading...'),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _downloadProgress),
                ],
              ),
            )
          else if (_searching)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text('Type a query and press search'),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final v = _results[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${v.surahName} : ${v.ayatNo}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'score: ${v.score.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildHighlightedText(v.textHilight ?? v.textArabic),
                                const SizedBox(height: 4),
                                Text(
                                  v.textIndonesian,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
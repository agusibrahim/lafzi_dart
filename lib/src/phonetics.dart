/// Phonetic conversion for Arabic transliteration search.
///
/// Converts Latin transliteration (lafadz) to phonetic code
/// matching the original Lafzi algorithm.
library;

/// Converts Latin text to phonetic code (with vowels preserved).
String convert(String input) {
  var s = input.toUpperCase();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll('-', ' ');
  s = s.replaceAll(RegExp(r"[^A-Z`'\-\s]"), '');

  s = _substitusiVokal(s);
  s = _gabungKonsonan(s);
  s = _gabungVokal(s);
  s = _substitusiDiftong(s);
  s = _tandaiHamzah(s);
  s = _substitusiIkhfa(s);
  s = _substitusiIqlab(s);
  s = _substitusiIdgham(s);
  s = _fonetik2Konsonan(s);
  s = _fonetik1Konsonan(s);
  s = s.replaceAll(' ', '');

  return s;
}

/// Converts Latin text to phonetic code (vowels stripped).
String convertNoVowel(String input) {
  var s = convert(input);
  s = s.replaceAll(RegExp(r'[AIU]'), '');
  return s;
}

// --- Substitution stages ---

String _substitusiVokal(String s) {
  s = s.replaceAll('O', 'A');
  s = s.replaceAll('E', 'I');
  return s;
}

String _gabungKonsonan(String s) {
  // Merge adjacent identical consonants
  s = s.replaceAllMapped(
    RegExp(r'([BCDFGHJKLMNPQRSTVWXYZ])\s?\1+'),
    (m) => m.group(1)!,
  );
  // Merge adjacent identical double consonants (KH, SH, etc.)
  s = s.replaceAllMapped(
    RegExp(r'(KH|CH|SH|TS|SY|DH|TH|ZH|DZ|GH)\s?\1+'),
    (m) => m.group(1)!,
  );
  return s;
}

String _gabungVokal(String s) {
  s = s.replaceAllMapped(RegExp(r'([AIUEO])\1+'), (m) => m.group(1)!);
  return s;
}

String _substitusiDiftong(String s) {
  s = s.replaceAll('AI', 'AY');
  s = s.replaceAll('AU', 'AW');
  return s;
}

String _tandaiHamzah(String s) {
  // After space or at start of string
  s = s.replaceFirstMapped(RegExp(r'^(A|I|U)'), (m) => ' X${m.group(1)}');
  s = s.replaceAllMapped(RegExp(r'\s(A|I|U)'), (m) => ' X${m.group(1)}');
  // IA, IU => IXA, IXU
  s = s.replaceAllMapped(RegExp(r'I(A|U)'), (m) => 'IX${m.group(1)}');
  // UA, UI => UXA, UXI
  s = s.replaceAllMapped(RegExp(r'U(A|I)'), (m) => 'UX${m.group(1)}');
  return s;
}

String _substitusiIkhfa(String s) {
  s = s.replaceAllMapped(
    RegExp(r'(A|I|U)NG\s?(D|F|J|K|P|Q|S|T|V|Z)'),
    (m) => '${m.group(1)}N${m.group(2)}',
  );
  return s;
}

String _substitusiIqlab(String s) {
  s = s.replaceAll(RegExp(r'N\s?B'), 'MB');
  return s;
}

String _substitusiIdgham(String s) {
  // Exceptions
  s = s.replaceAll('DUNYA', 'DUN_YA');
  s = s.replaceAll('BUNYAN', 'BUN_YAN');
  s = s.replaceAll('QINWAN', 'KIN_WAN');
  s = s.replaceAll('KINWAN', 'KIN_WAN');
  s = s.replaceAll('SINWAN', 'SIN_WAN');
  s = s.replaceAll('SHINWAN', 'SIN_WAN');

  s = s.replaceAllMapped(
    RegExp(r'N\s?(N|M|L|R|Y|W)'),
    (m) => m.group(1)!,
  );

  // Restore exceptions
  s = s.replaceAll('DUN_YA', 'DUNYA');
  s = s.replaceAll('BUN_YAN', 'BUNYAN');
  s = s.replaceAll('KIN_WAN', 'KINWAN');
  s = s.replaceAll('SIN_WAN', 'SINWAN');
  return s;
}

String _fonetik2Konsonan(String s) {
  s = s.replaceAll(RegExp(r'KH|CH'), 'H');
  s = s.replaceAll(RegExp(r'SH|TS|SY'), 'S');
  s = s.replaceAll('DH', 'D');
  s = s.replaceAll(RegExp(r'ZH|DZ'), 'Z');
  s = s.replaceAll('TH', 'T');
  s = s.replaceAllMapped(
    RegExp(r'NG(A|I|U)'),
    (m) => 'X${m.group(1)}',
  );
  s = s.replaceAll('GH', 'G');
  return s;
}

String _fonetik1Konsonan(String s) {
  s = s.replaceAll(RegExp(r"[`']"), 'X');
  s = s.replaceAll(RegExp(r'[QK]'), 'K');
  s = s.replaceAll(RegExp(r'[FVP]'), 'F');
  s = s.replaceAll(RegExp(r'[JZ]'), 'Z');
  return s;
}
/// Converts a Latin (lafadz) text into a phonetic code.
String convert(String input) {
  // Preprocessing: uppercase, single spaces, replace - with space, remove non-alphabetic chars except ` and '
  String s = input.toUpperCase();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(RegExp(r'\-'), ' ');
  s = s.replaceAll(RegExp(r"[^A-Z`'\-\s]"), '');

  // Transformations
  s = _idSubstitusiVokal(s);
  s = _idGabungKonsonan(s);
  s = _idGabungVokal(s);
  s = _idSubstitusiDiftong(s);
  s = _idTandaiHamzah(s);
  s = _idSubstitusiIkhfa(s);
  s = _idSubstitusiIqlab(s);
  s = _idSubstitusiIdgham(s);
  s = _idFonetik2Konsonan(s);
  s = _idFonetik1Konsonan(s);
  s = _idHilangkanSpasi(s);

  return s;
}

/// Converts a Latin (lafadz) text into a phonetic code, with vowels removed.
String convertNoVowel(String input) {
  // Preprocessing: uppercase, single spaces, replace - with space, remove non-alphabetic chars except ` and '
  String s = input.toUpperCase();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(RegExp(r'\-'), ' ');
  s = s.replaceAll(RegExp(r"[^A-Z`'\-\s]"), '');

  // Transformations
  s = _idSubstitusiVokal(s);
  s = _idGabungKonsonan(s);
  s = _idGabungVokal(s);
  s = _idSubstitusiDiftong(s);
  s = _idTandaiHamzah(s);
  s = _idSubstitusiIkhfa(s);
  s = _idSubstitusiIqlab(s);
  s = _idSubstitusiIdgham(s);
  s = _idFonetik2Konsonan(s);
  s = _idFonetik1Konsonan(s);
  s = _idHilangkanSpasi(s);
  s = _idHilangkanVokal(s);

  return s;
}

// Substitutes vowels not present in Arabic.
String _idSubstitusiVokal(String s) {
  s = s.replaceAll('O', 'A');
  s = s.replaceAll('E', 'I');
  return s;
}

// Merges identical adjacent consonants.
String _idGabungKonsonan(String s) {
  // Merge adjacent identical consonants
  s = s.replaceAll(RegExp(r'(B|C|D|F|G|H|J|K|L|M|N|P|Q|R|S|T|V|W|X|Y|Z)\s?\1+'), r'$1');
  // For two-consonant combinations (KH, SH, etc.)
  s = s.replaceAll(RegExp(r'(KH|CH|SH|TS|SY|DH|TH|ZH|DZ|GH)\s?\1+'), r'$1');
  return s;
}

// Merges identical adjacent vowels.
String _idGabungVokal(String s) {
  // Merge directly adjacent identical vowels
  s = s.replaceAll(RegExp(r'(A|I|U|E|O)\1+'), r'$1');
  return s;
}

// Substitutes Arabic diphthongs.
String _idSubstitusiDiftong(String s) {
  s = s.replaceAll('AI', 'AY');
  s = s.replaceAll('AU', 'AW');
  return s;
}

// Marks hamzah.
String _idTandaiHamzah(String s) {
  // After space or at the beginning of the string
  s = s.replaceAll(RegExp(r'^(A|I|U)'), r' X$1');
  s = s.replaceAll(RegExp(r'\s(A|I|U)'), r' X$1');

  // IA, IU => IXA, IXU
  s = s.replaceAll(RegExp(r'I(A|U)'), r'IX$1');

  // UA, UI => UXA, UXI
  s = s.replaceAll(RegExp(r'U(A|I)'), r'UX$1');

  return s;
}

// Substitutes ikhfa letters (NG).
String _idSubstitusiIkhfa(String s) {
  // [vowel][NG][consonant] => [vowel][N][consonant]
  s = s.replaceAll(RegExp(r'(A|I|U)NG\s?(D|F|J|K|P|Q|S|T|V|Z)'), r'$1N$2');
  return s;
}

// Substitutes iqlab letters.
String _idSubstitusiIqlab(String s) {
  // NB => MB
  s = s.replaceAll(RegExp(r'N\s?B'), 'MB');
  return s;
}

// Substitutes idgham letters.
String _idSubstitusiIdgham(String s) {
  // Exceptions
  s = s.replaceAll('DUNYA', 'DUN_YA');
  s = s.replaceAll('BUNYAN', 'BUN_YAN');
  s = s.replaceAll('QINWAN', 'KIN_WAN');
  s = s.replaceAll('KINWAN', 'KIN_WAN');
  s = s.replaceAll('SINWAN', 'SIN_WAN');
  s = s.replaceAll('SHINWAN', 'SIN_WAN');

  // N,M,L,R,Y,W
  s = s.replaceAll(RegExp(r'N\s?(N|M|L|R|Y|W)'), r'$1');

  // Restore exceptions
  s = s.replaceAll('DUN_YA', 'DUNYA');
  s = s.replaceAll('BUN_YAN', 'BUNYAN');
  s = s.replaceAll('KIN_WAN', 'KINWAN');
  s = s.replaceAll('SIN_WAN', 'SINWAN');

  return s;
}

// Substitutes 2-consonant phonetics.
String _idFonetik2Konsonan(String s) {
  s = s.replaceAll(RegExp(r'KH|CH'), 'H');
  s = s.replaceAll(RegExp(r'SH|TS|SY'), 'S');
  s = s.replaceAll(RegExp(r'DH'), 'D');
  s = s.replaceAll(RegExp(r'ZH|DZ'), 'Z');
  s = s.replaceAll(RegExp(r'TH'), 'T');
  s = s.replaceAll(RegExp(r'NG(A|I|U)'), r'X$1'); // Handles "ngalamin"
  s = s.replaceAll(RegExp(r'GH'), 'G');
  return s;
}

// Substitutes 1-consonant phonetics.
String _idFonetik1Konsonan(String s) {
  s = s.replaceAll(RegExp(r"''|`"), 'X');
  s = s.replaceAll(RegExp(r'Q|K'), 'K');
  s = s.replaceAll(RegExp(r'F|V|P'), 'F');
  s = s.replaceAll(RegExp(r'J|Z'), 'Z');
  return s;
}

// Removes spaces.
String _idHilangkanSpasi(String s) {
  return s.replaceAll(RegExp(r'\s'), '');
}

// Removes vowels.
String _idHilangkanVokal(String s) {
  return s.replaceAll(RegExp(r'A|I|U'), '');
}

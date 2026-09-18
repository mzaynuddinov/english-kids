class VoiceSelection {
  final Map<String, String>? voice;
  final bool genderMatched;
  final bool englishMatched;
  final String requestedGender;

  const VoiceSelection({
    required this.requestedGender,
    this.voice,
    this.genderMatched = false,
    this.englishMatched = false,
  });

  bool get hasVoice => voice != null;
}

bool _isEnglishLocale(String locale) {
  final value = locale.toLowerCase().replaceAll('_', '-');
  return value == 'en' || value.startsWith('en-') || value.startsWith('eng');
}

String? _genderOf(Map<String, String> voice) {
  final explicit = (voice['gender'] ?? '').trim().toLowerCase();
  if (explicit == 'male' || explicit == 'female') return explicit;

  final name = (voice['name'] ?? '').toLowerCase();
  final locale = (voice['locale'] ?? '').toLowerCase();
  final blob = '$name $locale';

  const femaleHints = [
    'female',
    'woman',
    'girl',
    'feminine',
  ];
  const maleHints = [
    'male',
    'man',
    'boy',
    'masculine',
  ];

  for (final hint in femaleHints) {
    if (blob.contains(hint)) return 'female';
  }
  for (final hint in maleHints) {
    if (RegExp('\\b$hint\\b').hasMatch(blob) || blob.contains('#male') || blob.contains('-male')) {
      return 'male';
    }
  }

  // Android quality-voice codes sometimes include f/m, but names like
  // "Samantha" are device-specific and must not be required.
  if (blob.contains('samantha') ||
      blob.contains('zira') ||
      blob.contains('karen') ||
      blob.contains('moira') ||
      blob.contains('tessa') ||
      blob.contains('fiona') ||
      blob.contains('ava')) {
    return 'female';
  }
  if (blob.contains('daniel') ||
      blob.contains('david') ||
      blob.contains('mark') ||
      blob.contains('ravi') ||
      blob.contains('aaron') ||
      blob.contains('fred')) {
    return 'male';
  }
  return null;
}

List<Map<String, String>> normalizeVoices(dynamic raw) {
  final result = <Map<String, String>>[];
  if (raw is! List) return result;
  for (final item in raw) {
    if (item is! Map) continue;
    final name = '${item['name'] ?? ''}'.trim();
    final locale = '${item['locale'] ?? ''}'.trim();
    if (name.isEmpty) continue;
    result.add({
      'name': name,
      'locale': locale,
      'gender': '${item['gender'] ?? ''}'.trim(),
    });
  }
  return result;
}

VoiceSelection selectEnglishVoice({
  required List<Map<String, String>> voices,
  required String gender,
}) {
  final requested = gender == 'male' ? 'male' : 'female';
  final english = voices.where((v) => _isEnglishLocale(v['locale'] ?? '')).toList();
  final pool = english.isNotEmpty ? english : voices;

  Map<String, String>? gendered;
  for (final voice in pool) {
    if (_genderOf(voice) == requested) {
      gendered = voice;
      break;
    }
  }

  if (gendered != null) {
    return VoiceSelection(
      requestedGender: requested,
      voice: gendered,
      genderMatched: true,
      englishMatched: english.contains(gendered) || _isEnglishLocale(gendered['locale'] ?? ''),
    );
  }

  final fallback = pool.isEmpty ? null : pool.first;
  return VoiceSelection(
    requestedGender: requested,
    voice: fallback,
    genderMatched: false,
    englishMatched: fallback != null && _isEnglishLocale(fallback['locale'] ?? ''),
  );
}

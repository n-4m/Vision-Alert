import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;

    await _tts.setLanguage("vi-VN");
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _initialized = true;
  }

  Future<void> speak(String text) async {
    await _init();
    await _tts.stop(); // tránh nói chồng tiếng
    await _tts.speak(text);
  }
}

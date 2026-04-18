import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceDemoScreen extends StatefulWidget {
  const VoiceDemoScreen({super.key});

  @override
  State<VoiceDemoScreen> createState() => _VoiceDemoScreenState();
}

class _VoiceDemoScreenState extends State<VoiceDemoScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechAvailable = false;
  bool _isListening = false;
  String _spokenText = 'Tap the microphone and speak.';
  String _selectedLocaleId = 'en_US';

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() {
          _isListening = status == 'listening';
        });
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech error: ${error.errorMsg}')),
        );
      },
    );

    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _spokenText = result.recognizedWords.isEmpty
              ? 'No speech detected.'
              : result.recognizedWords;
        });
      },
      localeId: _selectedLocaleId,
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      onDevice: true,
      cancelOnError: true,
    );

    if (!mounted) return;
    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _speakText() async {
    if (_spokenText.trim().isEmpty) return;

    await _tts.setLanguage(_selectedLocaleId.replaceAll('_', '-'));
    await _tts.speak(_spokenText);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Input Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedLocaleId,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'en_US',
                  child: Text('English (US)'),
                ),
                DropdownMenuItem(
                  value: 'ne_NP',
                  child: Text('Nepali'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedLocaleId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      _spokenText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(_isListening ? 'Stop Listening' : 'Start Mic'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _speakText,
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('Speak Text'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _stopSpeaking,
                    icon: const Icon(Icons.volume_off_outlined),
                    label: const Text('Stop Audio'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
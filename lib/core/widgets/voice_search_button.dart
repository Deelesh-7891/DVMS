import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// A mic icon button that listens for one utterance and hands the caller
/// back the digits it heard (last 3-4 digits of a registration number,
/// e.g. "double eight nine one two" -> "8912") — or, if fewer than 3
/// digits were understood, the raw transcript instead, so a caller can
/// still fall back to a plain text search.
///
/// Silently disables itself if speech recognition isn't available on the
/// device — this is always additive to typing, never a replacement it
/// depends on.
class VoiceSearchButton extends StatefulWidget {
  final ValueChanged<String> onResult;
  final String tooltip;

  const VoiceSearchButton({
    super.key,
    required this.onResult,
    this.tooltip = "Say the last 4 digits of the reg no",
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  bool _checkedAvailability = false;
  bool _available = true;

  static const Map<String, String> _numberWords = {
    "zero": "0", "oh": "0", "one": "1", "won": "1", "two": "2", "to": "2",
    "too": "2", "three": "3", "four": "4", "for": "4", "five": "5",
    "six": "6", "seven": "7", "eight": "8", "ate": "8", "nine": "9",
    "double": "",
  };

  /// Same digit-extraction heuristic as the web's digitsFromSpeech().
  String _digitsFromSpeech(String transcript) {
    final lower = transcript.toLowerCase();
    final direct = lower.replaceAll(RegExp(r'[^0-9]'), '');
    if (direct.length >= 4) return direct;

    final mapped = lower
        .split(RegExp(r'\s+'))
        .map((w) => _numberWords[w] ?? w.replaceAll(RegExp(r'[^0-9]'), ''))
        .join();
    return mapped.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _start() async {
    if (_listening) return;

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (error) {
        if (mounted) setState(() => _listening = false);
      },
    );

    if (!available) {
      setState(() {
        _checkedAvailability = true;
        _available = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Voice input is not available on this device."),
          ),
        );
      }
      return;
    }

    setState(() => _listening = true);

    await _speech.listen(
      localeId: "en_IN",
      onResult: (result) {
        if (!result.finalResult) return;

        final transcript = result.recognizedWords;
        final digits = _digitsFromSpeech(transcript);
        setState(() => _listening = false);
        _speech.stop();
        widget.onResult(digits.length >= 3 ? digits : transcript.trim());
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkedAvailability && !_available) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _listening ? null : _start,
      icon: Icon(
        _listening ? Icons.mic : Icons.mic_none,
        color: _listening ? Colors.red : null,
      ),
    );
  }
}

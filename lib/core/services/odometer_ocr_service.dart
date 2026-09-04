import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Reads an odometer reading off a photo using Google ML Kit's on-device
/// text recognition (free, offline, no API key/billing setup — same
/// "just works" experience as the Tesseract.js OCR already on the web
/// fuel.html page).
///
/// Uses the same digit-extraction heuristic as that web implementation:
/// fix common OCR digit/letter confusions (O/o -> 0, I/l/| -> 1), then
/// take the longest 3-7 digit run found — odometers are plain digit
/// strings, everything else on the dashboard (warning icons, fuel gauge
/// text, etc.) is noise this filters out.
class OdometerOcrService {
  static final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Returns the best-guess odometer reading as a digit string, or null
  /// if nothing digit-like was found. Never throws — OCR failures should
  /// never block manual entry, so callers can just fall back silently.
  static Future<String?> recognizeFromPath(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText result =
          await _recognizer.processImage(inputImage);

      final cleaned = result.text.replaceAllMapped(
        RegExp(r'[OoIl|]'),
        (m) {
          switch (m.group(0)) {
            case 'O':
            case 'o':
              return '0';
            case 'I':
            case 'l':
            case '|':
              return '1';
            default:
              return m.group(0)!;
          }
        },
      );

      final candidates = RegExp(r'\d{3,7}')
          .allMatches(cleaned)
          .map((m) => m.group(0)!)
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));

      return candidates.isNotEmpty ? candidates.first : null;
    } catch (_) {
      return null;
    }
  }

  /// Call once when the app shuts down / the feature is no longer needed.
  /// Not required per-screen — the recognizer is cheap to keep alive for
  /// the app's lifetime, so screens using this don't need to manage it.
  static Future<void> dispose() => _recognizer.close();
}

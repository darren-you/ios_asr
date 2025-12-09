# ios_asr

[中文](README.md) | **English**

A Flutter plugin for iOS Automatic Speech Recognition (ASR) based on Pigeon, utilizing Apple's SFSpeechRecognizer and AVAudioEngine.

## Features

- ✅ Real-time speech recognition
- ✅ Support for multiple languages and locales
- ✅ Real-time partial recognition results
- ✅ Sound level monitoring
- ✅ Permission management
- ✅ Type-safe platform communication using Pigeon

## Tech Stack

- **Flutter/Dart**: Cross-platform framework
- **Pigeon**: Type-safe platform communication code generation tool
- **iOS SFSpeechRecognizer**: Apple's speech recognition framework
- **AVAudioEngine**: Audio engine for capturing microphone input

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ios_asr:
    path: ../ios_asr
```

## Permission Configuration

Add the following permissions to your iOS project's `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone for speech recognition</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs access to speech recognition to convert your speech to text</string>
```

## Example App

The example folder contains a complete sample application demonstrating how to use the ios_asr plugin for real-time speech recognition.

<table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/darren-you/ios_asr/main/docs/AsrHomePage.PNG" alt="Real-time Recognition Page" width="300"/></td>
    <td><img src="https://raw.githubusercontent.com/darren-you/ios_asr/main/docs/AdvancedFeaturesPage.PNG" alt="Advanced Features Page" width="300"/></td>
  </tr>
  <tr>
    <td align="center"><b>Real-time Recognition</b></td>
    <td align="center"><b>Advanced Features</b></td>
  </tr>
</table>

## Usage Examples

### Basic Usage

```dart
import 'package:ios_asr/ios_asr.dart';

final asr = IosAsr();

// Check permission
final hasPermission = await asr.hasPermission();
if (!hasPermission) {
  await asr.requestPermission();
}

// Get available locales
final locales = await asr.getAvailableLocales();

// Start speech recognition
await asr.startListening(
  localeIdentifier: 'zh-CN',
  partialResults: true,
);

// Stop speech recognition
await asr.stopListening();

// Cancel speech recognition
await asr.cancelListening();
```

### Listening to Recognition Results

```dart
// Listen to recognition results
asr.resultStream.listen((result) {
  print('Recognized text: ${result.text}');
  print('Is final: ${result.isFinal}');
  print('Confidence: ${result.confidence}');
});

// Listen to status changes
asr.statusStream.listen((status) {
  switch (status) {
    case AsrStatus.listening:
      print('Listening...');
      break;
    case AsrStatus.stopped:
      print('Stopped');
      break;
    case AsrStatus.done:
      print('Done');
      break;
    case AsrStatus.error:
      print('Error');
      break;
  }
});

// Listen to errors
asr.errorStream.listen((error) {
  print('Error: ${error.code} - ${error.message}');
});

// Listen to sound level
asr.soundLevelStream.listen((level) {
  print('Sound level: $level');
});
```

## API Documentation

### IosAsr Class

#### Methods

- `Future<bool> hasPermission()` - Check if permissions are granted
- `Future<bool> requestPermission()` - Request microphone and speech recognition permissions
- `Future<List<AsrLocaleInfo>> getAvailableLocales()` - Get list of supported languages
- `Future<bool> startListening({String? localeIdentifier, bool partialResults})` - Start speech recognition
- `Future<void> stopListening()` - Stop speech recognition
- `Future<void> cancelListening()` - Cancel speech recognition

#### Streams

- `Stream<AsrStatus> statusStream` - Status change stream
- `Stream<AsrRecognitionResult> resultStream` - Recognition result stream
- `Stream<AsrError> errorStream` - Error stream
- `Stream<double> soundLevelStream` - Sound level stream (0.0 - 1.0)

### Data Models

#### AsrLocaleInfo

```dart
class AsrLocaleInfo {
  final String identifier;     // Locale identifier, e.g., "zh-CN"
  final String displayName;     // Display name
}
```

#### AsrRecognitionResult

```dart
class AsrRecognitionResult {
  final String text;           // Recognized text
  final bool isFinal;          // Whether it's a final result
  final double? confidence;    // Confidence score (only available for final results)
}
```

#### AsrError

```dart
class AsrError {
  final String code;           // Error code
  final String message;        // Error message
}
```

#### AsrStatus

```dart
enum AsrStatus {
  listening,   // Currently listening
  stopped,     // Stopped
  cancelled,   // Cancelled
  done,        // Done
  error,       // Error
}
```

## Project Structure

```
ios_asr/
├── lib/
│   ├── ios_asr.dart              # Main API wrapper
│   └── src/
│       └── ios_asr_api.g.dart    # Pigeon generated code
├── ios/
│   └── Classes/
│       ├── IosAsrPlugin.swift    # iOS implementation
│       └── IosAsrApi.g.swift     # Pigeon generated Swift code
├── pigeon_asr_api.dart           # Pigeon API definition
└── example/
    └── lib/
        └── main.dart             # Example app
```

## Development

### Modifying API Definition

1. Edit the `pigeon_asr_api.dart` file
2. Run `dart run pigeon --input pigeon_asr_api.dart` to generate code
3. Implement the new API functionality

### Running the Example

```bash
cd example
flutter run
```

## Limitations

- iOS platform only
- Requires iOS 10.0 or higher
- Requires device support for speech recognition
- Requires network connection (Apple's speech recognition service)

## References

- [Apple Speech Framework](https://developer.apple.com/documentation/speech)
- [SFSpeechRecognizer](https://developer.apple.com/documentation/speech/sfspeechrecognizer)
- [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Pigeon](https://pub.dev/packages/pigeon)

## License

MIT License

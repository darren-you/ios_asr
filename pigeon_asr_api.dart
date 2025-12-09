import 'package:pigeon/pigeon.dart';

class AsrLocaleInfo {
  AsrLocaleInfo({required this.identifier, required this.displayName});
  final String identifier;
  final String displayName;
}

class AsrTranscriptionSegment {
  AsrTranscriptionSegment({
    required this.substring,
    required this.timestamp,
    required this.duration,
    this.confidence,
  });
  final String substring;
  final double timestamp;
  final double duration;
  final double? confidence;
}

class AsrRecognitionResult {
  AsrRecognitionResult({
    required this.text,
    required this.isFinal,
    this.confidence,
    this.segments,
    this.speakingRate,
    this.averagePauseDuration,
  });
  final String text;
  final bool isFinal;
  final double? confidence;
  final List<AsrTranscriptionSegment?>? segments;
  final double? speakingRate;
  final double? averagePauseDuration;
}

class AsrError {
  AsrError({required this.code, required this.message});
  final String code;
  final String message;
}

class AsrRecognitionOptions {
  AsrRecognitionOptions({
    this.localeIdentifier,
    this.partialResults = true,
    this.taskHint,
    this.requiresOnDeviceRecognition = false,
    this.contextualStrings,
    this.detectMultipleUtterances = false,
    this.addsPunctuation = false,
  });
  final String? localeIdentifier;
  final bool partialResults;
  final String? taskHint;
  final bool requiresOnDeviceRecognition;
  final List<String?>? contextualStrings;
  final bool detectMultipleUtterances;
  final bool addsPunctuation;
}

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/ios_asr_api.g.dart',
    dartOptions: DartOptions(),
    dartPackageName: 'ios_asr',
    swiftOut: 'ios/Classes/IosAsrApi.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
@HostApi()
abstract class AsrHostApi {
  bool hasPermission();

  @async
  bool requestPermission();

  List<AsrLocaleInfo> getAvailableLocales();

  @async
  bool startListening(String? localeIdentifier, bool partialResults);

  @async
  bool startListeningWithOptions(AsrRecognitionOptions options);

  @async
  bool recognizeAudioFile(String filePath, AsrRecognitionOptions options);

  void stopListening();

  void cancelListening();
  
  bool isOnDeviceRecognitionAvailable();
}

@FlutterApi()
abstract class AsrFlutterApi {
  void onRecognitionResult(AsrRecognitionResult result);

  void onError(AsrError error);

  void onStatusChanged(String status);

  void onSoundLevelChanged(double level);
}

import 'dart:async';
import 'src/ios_asr_api.g.dart';

export 'src/ios_asr_api.g.dart' show AsrLocaleInfo, AsrRecognitionResult, AsrError, AsrTranscriptionSegment, AsrRecognitionOptions;

enum AsrStatus {
  listening,
  stopped,
  cancelled,
  done,
  error,
}

class IosAsr implements AsrFlutterApi {
  static IosAsr? _instance;
  factory IosAsr() {
    _instance ??= IosAsr._internal();
    return _instance!;
  }

  IosAsr._internal() {
    AsrFlutterApi.setUp(this);
  }

  final _hostApi = AsrHostApi();
  
  final _statusController = StreamController<AsrStatus>.broadcast();
  final _resultController = StreamController<AsrRecognitionResult>.broadcast();
  final _errorController = StreamController<AsrError>.broadcast();
  final _soundLevelController = StreamController<double>.broadcast();

  Stream<AsrStatus> get statusStream => _statusController.stream;
  Stream<AsrRecognitionResult> get resultStream => _resultController.stream;
  Stream<AsrError> get errorStream => _errorController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;

  Future<bool> hasPermission() async {
    return await _hostApi.hasPermission();
  }

  Future<bool> requestPermission() async {
    return await _hostApi.requestPermission();
  }

  Future<List<AsrLocaleInfo>> getAvailableLocales() async {
    return await _hostApi.getAvailableLocales();
  }

  Future<bool> startListening({
    String? localeIdentifier,
    bool partialResults = true,
  }) async {
    return await _hostApi.startListening(localeIdentifier, partialResults);
  }

  Future<bool> startListeningWithOptions(AsrRecognitionOptions options) async {
    return await _hostApi.startListeningWithOptions(options);
  }

  Future<bool> recognizeAudioFile(String filePath, {AsrRecognitionOptions? options}) async {
    final opts = options ?? AsrRecognitionOptions(
      partialResults: false,
      requiresOnDeviceRecognition: false,
      detectMultipleUtterances: false,
      addsPunctuation: false,
    );
    return await _hostApi.recognizeAudioFile(filePath, opts);
  }

  Future<void> stopListening() async {
    await _hostApi.stopListening();
  }

  Future<void> cancelListening() async {
    await _hostApi.cancelListening();
  }

  Future<bool> isOnDeviceRecognitionAvailable() async {
    return await _hostApi.isOnDeviceRecognitionAvailable();
  }

  @override
  void onRecognitionResult(AsrRecognitionResult result) {
    _resultController.add(result);
  }

  @override
  void onError(AsrError error) {
    _errorController.add(error);
  }

  @override
  void onStatusChanged(String status) {
    final asrStatus = _parseStatus(status);
    _statusController.add(asrStatus);
  }

  @override
  void onSoundLevelChanged(double level) {
    _soundLevelController.add(level);
  }

  AsrStatus _parseStatus(String status) {
    switch (status) {
      case 'listening':
        return AsrStatus.listening;
      case 'stopped':
        return AsrStatus.stopped;
      case 'cancelled':
        return AsrStatus.cancelled;
      case 'done':
        return AsrStatus.done;
      case 'error':
        return AsrStatus.error;
      default:
        return AsrStatus.stopped;
    }
  }

  void dispose() {
    _statusController.close();
    _resultController.close();
    _errorController.close();
    _soundLevelController.close();
  }
}

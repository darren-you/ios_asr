import Flutter
import UIKit
import Speech
import AVFoundation

public class IosAsrPlugin: NSObject, FlutterPlugin {
    private var flutterApi: AsrFlutterApi?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let api = AsrHostApiImpl()
        AsrHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: api)
        api.flutterApi = AsrFlutterApi(binaryMessenger: registrar.messenger())
    }
}

private class AsrHostApiImpl: NSObject, AsrHostApi {
    var flutterApi: AsrFlutterApi?
    
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var isListening = false
    
    func hasPermission() throws -> Bool {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let microphoneStatus = audioSession.recordPermission
        
        return speechStatus == .authorized && microphoneStatus == .granted
    }
    
    func requestPermission(completion: @escaping (Result<Bool, Error>) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == .authorized {
                self.audioSession.requestRecordPermission { granted in
                    completion(.success(granted))
                }
            } else {
                completion(.success(false))
            }
        }
    }
    
    func getAvailableLocales() throws -> [AsrLocaleInfo] {
        let locales = SFSpeechRecognizer.supportedLocales()
        return locales.map { locale in
            AsrLocaleInfo(
                identifier: locale.identifier,
                displayName: locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
            )
        }
    }
    
    func startListening(localeIdentifier: String?, partialResults: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        if isListening {
            completion(.failure(NSError(domain: "AsrError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Already listening"])))
            return
        }
        
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }
        
        guard let audioEngine = audioEngine else {
            completion(.failure(NSError(domain: "AsrError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio engine"])))
            return
        }
        
        let locale: Locale
        if let localeId = localeIdentifier {
            locale = Locale(identifier: localeId)
        } else {
            locale = Locale.current
        }
        
        recognizer = SFSpeechRecognizer(locale: locale)
        
        guard let recognizer = recognizer else {
            completion(.failure(NSError(domain: "AsrError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available for this locale"])))
            return
        }
        
        guard recognizer.isAvailable else {
            completion(.failure(NSError(domain: "AsrError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])))
            return
        }
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine.inputNode
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                completion(.failure(NSError(domain: "AsrError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])))
                return
            }
            
            recognitionRequest.shouldReportPartialResults = partialResults
            
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let recognitionResult = AsrRecognitionResult(
                        text: result.bestTranscription.formattedString,
                        isFinal: result.isFinal,
                        confidence: result.isFinal && !result.transcriptions.isEmpty 
                            ? Double(result.transcriptions[0].segments.first?.confidence ?? 0) 
                            : nil
                    )
                    
                    self.flutterApi?.onRecognitionResult(result: recognitionResult) { _ in }
                    
                    if result.isFinal {
                        self.stopListeningInternal()
                        self.flutterApi?.onStatusChanged(status: "done") { _ in }
                    }
                }
                
                if let error = error {
                    let asrError = AsrError(
                        code: "recognition_error",
                        message: error.localizedDescription
                    )
                    self.flutterApi?.onError(error: asrError) { _ in }
                    self.stopListeningInternal()
                    self.flutterApi?.onStatusChanged(status: "error") { _ in }
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                self?.calculateSoundLevel(buffer: buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isListening = true
            flutterApi?.onStatusChanged(status: "listening") { _ in }
            completion(.success(true))
            
        } catch {
            completion(.failure(error))
        }
    }
    
    func stopListening() throws {
        stopListeningInternal()
        flutterApi?.onStatusChanged(status: "stopped") { _ in }
    }
    
    func cancelListening() throws {
        recognitionTask?.cancel()
        stopListeningInternal()
        flutterApi?.onStatusChanged(status: "cancelled") { _ in }
    }
    
    private func stopListeningInternal() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        
        isListening = false
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
        }
    }
    
    func startListeningWithOptions(options: AsrRecognitionOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        if isListening {
            completion(.failure(NSError(domain: "AsrError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Already listening"])))
            return
        }
        
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }
        
        guard let audioEngine = audioEngine else {
            completion(.failure(NSError(domain: "AsrError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio engine"])))
            return
        }
        
        let locale: Locale
        if let localeId = options.localeIdentifier {
            locale = Locale(identifier: localeId)
        } else {
            locale = Locale.current
        }
        
        recognizer = SFSpeechRecognizer(locale: locale)
        
        guard let recognizer = recognizer else {
            completion(.failure(NSError(domain: "AsrError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available for this locale"])))
            return
        }
        
        guard recognizer.isAvailable else {
            completion(.failure(NSError(domain: "AsrError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])))
            return
        }
        
        if options.requiresOnDeviceRecognition && !recognizer.supportsOnDeviceRecognition {
            completion(.failure(NSError(domain: "AsrError", code: 6, userInfo: [NSLocalizedDescriptionKey: "On-device recognition not supported"])))
            return
        }
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine.inputNode
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                completion(.failure(NSError(domain: "AsrError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])))
                return
            }
            
            recognitionRequest.shouldReportPartialResults = options.partialResults
            recognitionRequest.requiresOnDeviceRecognition = options.requiresOnDeviceRecognition
            
            if #available(iOS 13.0, *) {
                if let taskHint = options.taskHint {
                    switch taskHint {
                    case "unspecified":
                        recognitionRequest.taskHint = .unspecified
                    case "dictation":
                        recognitionRequest.taskHint = .dictation
                    case "search":
                        recognitionRequest.taskHint = .search
                    case "confirmation":
                        recognitionRequest.taskHint = .confirmation
                    default:
                        recognitionRequest.taskHint = .unspecified
                    }
                }
            }
            
            if #available(iOS 16.0, *) {
                if let contextualStrings = options.contextualStrings?.compactMap({ $0 }) {
                    recognitionRequest.contextualStrings = contextualStrings
                }
                recognitionRequest.addsPunctuation = options.addsPunctuation
            }
            
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let segments = self.extractSegments(from: result)
                    
                    let recognitionResult = AsrRecognitionResult(
                        text: result.bestTranscription.formattedString,
                        isFinal: result.isFinal,
                        confidence: result.isFinal && !result.transcriptions.isEmpty 
                            ? Double(result.transcriptions[0].segments.first?.confidence ?? 0) 
                            : nil,
                        segments: segments.isEmpty ? nil : segments,
                        speakingRate: result.isFinal ? result.bestTranscription.speakingRate : nil,
                        averagePauseDuration: result.isFinal ? result.bestTranscription.averagePauseDuration : nil
                    )
                    
                    DispatchQueue.main.async {
                        self.flutterApi?.onRecognitionResult(result: recognitionResult) { _ in }
                    }
                    
                    if result.isFinal {
                        self.stopListeningInternal()
                        DispatchQueue.main.async {
                            self.flutterApi?.onStatusChanged(status: "done") { _ in }
                        }
                    }
                }
                
                if let error = error {
                    let asrError = AsrError(
                        code: "recognition_error",
                        message: error.localizedDescription
                    )
                    DispatchQueue.main.async {
                        self.flutterApi?.onError(error: asrError) { _ in }
                    }
                    self.stopListeningInternal()
                    DispatchQueue.main.async {
                        self.flutterApi?.onStatusChanged(status: "error") { _ in }
                    }
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                self?.calculateSoundLevel(buffer: buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isListening = true
            DispatchQueue.main.async {
                self.flutterApi?.onStatusChanged(status: "listening") { _ in }
            }
            completion(.success(true))
            
        } catch {
            completion(.failure(error))
        }
    }
    
    func recognizeAudioFile(filePath: String, options: AsrRecognitionOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        let locale: Locale
        if let localeId = options.localeIdentifier {
            locale = Locale(identifier: localeId)
        } else {
            locale = Locale.current
        }
        
        let recognizer = SFSpeechRecognizer(locale: locale)
        
        guard let recognizer = recognizer else {
            completion(.failure(NSError(domain: "AsrError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available for this locale"])))
            return
        }
        
        guard recognizer.isAvailable else {
            completion(.failure(NSError(domain: "AsrError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])))
            return
        }
        
        if options.requiresOnDeviceRecognition && !recognizer.supportsOnDeviceRecognition {
            completion(.failure(NSError(domain: "AsrError", code: 6, userInfo: [NSLocalizedDescriptionKey: "On-device recognition not supported"])))
            return
        }
        
        let url = URL(fileURLWithPath: filePath)
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            completion(.failure(NSError(domain: "AsrError", code: 7, userInfo: [NSLocalizedDescriptionKey: "Audio file not found"])))
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = options.partialResults
        request.requiresOnDeviceRecognition = options.requiresOnDeviceRecognition
        
        if #available(iOS 13.0, *) {
            if let taskHint = options.taskHint {
                switch taskHint {
                case "unspecified":
                    request.taskHint = .unspecified
                case "dictation":
                    request.taskHint = .dictation
                case "search":
                    request.taskHint = .search
                case "confirmation":
                    request.taskHint = .confirmation
                default:
                    request.taskHint = .unspecified
                }
            }
        }
        
        if #available(iOS 16.0, *) {
            if let contextualStrings = options.contextualStrings?.compactMap({ $0 }) {
                request.contextualStrings = contextualStrings
            }
            request.addsPunctuation = options.addsPunctuation
        }
        
        DispatchQueue.main.async {
            self.flutterApi?.onStatusChanged(status: "listening") { _ in }
        }
        
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let segments = self.extractSegments(from: result)
                
                let recognitionResult = AsrRecognitionResult(
                    text: result.bestTranscription.formattedString,
                    isFinal: result.isFinal,
                    confidence: result.isFinal && !result.transcriptions.isEmpty 
                        ? Double(result.transcriptions[0].segments.first?.confidence ?? 0) 
                        : nil,
                    segments: segments.isEmpty ? nil : segments,
                    speakingRate: result.isFinal ? result.bestTranscription.speakingRate : nil,
                    averagePauseDuration: result.isFinal ? result.bestTranscription.averagePauseDuration : nil
                )
                
                DispatchQueue.main.async {
                    self.flutterApi?.onRecognitionResult(result: recognitionResult) { _ in }
                }
                
                if result.isFinal {
                    DispatchQueue.main.async {
                        self.flutterApi?.onStatusChanged(status: "done") { _ in }
                    }
                    completion(.success(true))
                }
            }
            
            if let error = error {
                let asrError = AsrError(
                    code: "recognition_error",
                    message: error.localizedDescription
                )
                DispatchQueue.main.async {
                    self.flutterApi?.onError(error: asrError) { _ in }
                    self.flutterApi?.onStatusChanged(status: "error") { _ in }
                }
                completion(.failure(error))
            }
        }
    }
    
    func isOnDeviceRecognitionAvailable() throws -> Bool {
        let recognizer = SFSpeechRecognizer()
        return recognizer?.supportsOnDeviceRecognition ?? false
    }
    
    private func extractSegments(from result: SFSpeechRecognitionResult) -> [AsrTranscriptionSegment] {
        let segments = result.bestTranscription.segments
        return segments.map { segment in
            AsrTranscriptionSegment(
                substring: segment.substring,
                timestamp: segment.timestamp,
                duration: segment.duration,
                confidence: Double(segment.confidence)
            )
        }
    }
    
    private func calculateSoundLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        ).map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        let normalizedLevel = max(0.0, min(1.0, Double((avgPower + 50) / 50)))
        
        DispatchQueue.main.async { [weak self] in
            self?.flutterApi?.onSoundLevelChanged(level: normalizedLevel) { _ in }
        }
    }
}

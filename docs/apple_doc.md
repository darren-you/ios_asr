以下是 iOS 使用 SFSpeechRecognizer 与 AVAudioEngine 进行语音识别的权威文档与示例链接，按主题归纳：

- 框架与概览
    - Speech 框架总览: https://developer.apple.com/documentation/speech
    - AVAudioEngine（音频采集/处理）: https://developer.apple.com/documentation/avfaudio/avaudioengine
    - AVAudioSession（音频会话/权限）: https://developer.apple.com/documentation/avfaudio/avaudiosession
    - AVAudioInputNode（输入节点/麦克风）: https://developer.apple.com/documentation/avfaudio/avaudioinputnode
- 关键类与 API
    - SFSpeechRecognizer: https://developer.apple.com/documentation/speech/sfspeechrecognizer
    - SFSpeechAudioBufferRecognitionRequest（实时音频流识别）: https://developer.apple.com/documentation/speech/sfspeechaudiobufferrecognitionrequest
    - SFSpeechURLRecognitionRequest（文件 URL 识别）: https://developer.apple.com/documentation/speech/sfspeechurlrecognitionrequest
    - SFSpeechRecognitionTask（识别任务）: https://developer.apple.com/documentation/speech/sfspeechrecognitiontask
    - 授权状态 SFSpeechRecognizerAuthorizationStatus: https://developer.apple.com/documentation/speech/sfspeechrecognizerauthorizationstatus
    - 请求授权 requestAuthorization(_:): https://developer.apple.com/documentation/speech/sfspeechrecognizer/1649877-requestauthorization
- 实操指南（强烈推荐）
    - 识别实时音频（使用 AVAudioEngine + SFSpeechRecognizer）: https://developer.apple.com/documentation/speech/recognizing_speech_in_live_audio
- 隐私与权限（Info.plist）
    - 麦克风使用描述（`NSMicrophoneUsageDescription`）: https://developer.apple.com/documentation/bundleresources/information_property_list/nsmicrophoneusagedescription
    - 语音识别使用描述（`NSSpeechRecognitionUsageDescription`）: https://developer.apple.com/documentation/bundleresources/information_property_list/nsspeechrecognitionusagedescription
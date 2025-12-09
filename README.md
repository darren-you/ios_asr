# ios_asr

一个基于 Pigeon 实现的 iOS 语音识别（ASR）Flutter 插件，使用 Apple 的 SFSpeechRecognizer 和 AVAudioEngine。

## 功能特性

- ✅ 实时语音识别
- ✅ 支持多种语言和地区
- ✅ 实时返回部分识别结果
- ✅ 音量级别监控
- ✅ 权限管理
- ✅ 使用 Pigeon 实现类型安全的平台通信

## 技术栈

- **Flutter/Dart**: 跨平台框架
- **Pigeon**: 类型安全的平台通信代码生成工具
- **iOS SFSpeechRecognizer**: Apple 语音识别框架
- **AVAudioEngine**: 音频引擎用于捕获麦克风输入

## 安装

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  ios_asr:
    path: ../ios_asr
```

## 权限配置

在 iOS 项目的 `Info.plist` 中添加以下权限：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone for speech recognition</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs access to speech recognition to convert your speech to text</string>
```

## 示例应用

example包含一个完整的示例应用，展示了如何使用 ios_asr 插件进行实时语音识别。

<table>
  <tr>
    <td><img src="https://github.com/darren-you/ios_asr/blob/master/docs/AsrHomePage.PNG" width="300"/></td>
    <td><img src="https://github.com/darren-you/ios_asr/blob/master/docs/AdvancedFeaturesPage.PNG" width="300"/></td>
  </tr>
  <tr>
    <td align="center"><b>实时识别</b></td>
    <td align="center"><b>高级功能</b></td>
  </tr>
</table>

### 基本用法

```dart
import 'package:ios_asr/ios_asr.dart';

final asr = IosAsr();

// 检查权限
final hasPermission = await asr.hasPermission();
if (!hasPermission) {
  await asr.requestPermission();
}

// 获取可用语言列表
final locales = await asr.getAvailableLocales();

// 开始语音识别
await asr.startListening(
  localeIdentifier: 'zh-CN',
  partialResults: true,
);

// 停止语音识别
await asr.stopListening();

// 取消语音识别
await asr.cancelListening();
```

### 监听识别结果

```dart
// 监听识别结果
asr.resultStream.listen((result) {
  print('识别文本: ${result.text}');
  print('是否最终结果: ${result.isFinal}');
  print('置信度: ${result.confidence}');
});

// 监听状态变化
asr.statusStream.listen((status) {
  switch (status) {
    case AsrStatus.listening:
      print('正在监听...');
      break;
    case AsrStatus.stopped:
      print('已停止');
      break;
    case AsrStatus.done:
      print('完成');
      break;
    case AsrStatus.error:
      print('错误');
      break;
  }
});

// 监听错误
asr.errorStream.listen((error) {
  print('错误: ${error.code} - ${error.message}');
});

// 监听音量级别
asr.soundLevelStream.listen((level) {
  print('音量级别: $level');
});
```

## API 文档

### IosAsr 类

#### 方法

- `Future<bool> hasPermission()` - 检查是否已授予权限
- `Future<bool> requestPermission()` - 请求麦克风和语音识别权限
- `Future<List<AsrLocaleInfo>> getAvailableLocales()` - 获取支持的语言列表
- `Future<bool> startListening({String? localeIdentifier, bool partialResults})` - 开始语音识别
- `Future<void> stopListening()` - 停止语音识别
- `Future<void> cancelListening()` - 取消语音识别

#### Stream

- `Stream<AsrStatus> statusStream` - 状态变化流
- `Stream<AsrRecognitionResult> resultStream` - 识别结果流
- `Stream<AsrError> errorStream` - 错误流
- `Stream<double> soundLevelStream` - 音量级别流 (0.0 - 1.0)

### 数据模型

#### AsrLocaleInfo

```dart
class AsrLocaleInfo {
  final String identifier;     // 语言标识符，如 "zh-CN"
  final String displayName;     // 显示名称
}
```

#### AsrRecognitionResult

```dart
class AsrRecognitionResult {
  final String text;           // 识别的文本
  final bool isFinal;          // 是否为最终结果
  final double? confidence;    // 置信度 (仅在最终结果时提供)
}
```

#### AsrError

```dart
class AsrError {
  final String code;           // 错误代码
  final String message;        // 错误消息
}
```

#### AsrStatus

```dart
enum AsrStatus {
  listening,   // 正在监听
  stopped,     // 已停止
  cancelled,   // 已取消
  done,        // 完成
  error,       // 错误
}
```

## 项目结构

```
ios_asr/
├── lib/
│   ├── ios_asr.dart              # 主要 API 封装
│   └── src/
│       └── ios_asr_api.g.dart    # Pigeon 生成的代码
├── ios/
│   └── Classes/
│       ├── IosAsrPlugin.swift    # iOS 实现
│       └── IosAsrApi.g.swift     # Pigeon 生成的 Swift 代码
├── pigeon_asr_api.dart           # Pigeon API 定义
└── example/
    └── lib/
        └── main.dart             # 示例应用
```

## 开发

### 修改 API 定义

1. 编辑 `pigeon_asr_api.dart` 文件
2. 运行 `dart run pigeon --input pigeon_asr_api.dart` 生成代码
3. 实现新的 API 功能

### 运行示例

```bash
cd example
flutter run
```

## 限制

- 仅支持 iOS 平台
- 需要 iOS 10.0 或更高版本
- 需要设备支持语音识别
- 依赖网络连接（Apple 的语音识别服务）

## 参考文档

- [Apple Speech Framework](https://developer.apple.com/documentation/speech)
- [SFSpeechRecognizer](https://developer.apple.com/documentation/speech/sfspeechrecognizer)
- [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Pigeon](https://pub.dev/packages/pigeon)

## 许可证

MIT License

# iOS ASR Plugin 功能列表

## 📋 已实现功能

### ✅ 核心实时识别功能 (100%)
- [x] 实时音频流识别 (SFSpeechAudioBufferRecognitionRequest)
- [x] AVAudioEngine 音频采集
- [x] 部分结果支持 (partialResults)
- [x] 实时音频电平监控
- [x] 开始/停止/取消识别

### ✅ 权限管理 (100%)
- [x] 检查权限状态 (hasPermission)
- [x] 请求语音识别授权 (SFSpeechRecognizer.requestAuthorization)
- [x] 请求麦克风授权 (AVAudioSession.requestRecordPermission)
- [x] Info.plist 权限配置
  - NSMicrophoneUsageDescription
  - NSSpeechRecognitionUsageDescription

### ✅ 多语言支持 (100%)
- [x] 获取支持的语言列表 (supportedLocales)
- [x] 指定识别语言 (localeIdentifier)
- [x] 检查识别器可用性 (recognizer.isAvailable)
- [x] 本地化语言显示名称

### ✅ 文件识别功能 (NEW - 100%)
- [x] 从音频文件 URL 识别 (SFSpeechURLRecognitionRequest)
- [x] 文件存在性检查
- [x] 支持所有音频格式 (wav, m4a, mp3等)

### ✅ 高级识别选项 (NEW - 100%)
- [x] **任务提示** (taskHint - iOS 13+)
  - unspecified: 未指定
  - dictation: 听写模式
  - search: 搜索模式
  - confirmation: 确认模式
- [x] **设备端识别** (requiresOnDeviceRecognition)
  - 本地处理，提升隐私
  - 无需网络连接
  - 检查设备支持 (supportsOnDeviceRecognition)
- [x] **上下文字符串** (contextualStrings - iOS 16+)
  - 提供专业词汇
  - 提升识别准确度
- [x] **自动标点** (addsPunctuation - iOS 16+)
  - 自动添加标点符号
- [x] **多段识别** (detectMultipleUtterances)
  - 检测多个独立语句

### ✅ 详细识别结果 (NEW - 100%)
- [x] **基础信息**
  - 识别文本 (text)
  - 最终结果标识 (isFinal)
  - 整体置信度 (confidence)
- [x] **分段信息** (segments - NEW)
  - 子字符串 (substring)
  - 时间戳 (timestamp)
  - 持续时间 (duration)
  - 分段置信度 (confidence)
- [x] **语音特征** (NEW)
  - 语速 (speakingRate)
  - 平均停顿时长 (averagePauseDuration)

### ✅ 任务控制 (100%)
- [x] 开始识别 (startListening)
- [x] 高级选项识别 (startListeningWithOptions - NEW)
- [x] 文件识别 (recognizeAudioFile - NEW)
- [x] 停止识别 (stopListening)
- [x] 取消识别 (cancelListening)
- [x] 任务状态回调 (listening/stopped/cancelled/done/error)

### ✅ 音频会话管理 (100%)
- [x] 音频类别设置 (.record)
- [x] 音频模式设置 (.measurement)
- [x] 音频会话激活/停用
- [x] 线程安全处理 (主线程调度)

## 📊 功能覆盖对比

| 功能类别 | Apple API | 已实现 | 覆盖率 |
|---------|-----------|--------|--------|
| **实时识别** | SFSpeechAudioBufferRecognitionRequest | ✅ | 100% |
| **文件识别** | SFSpeechURLRecognitionRequest | ✅ | 100% |
| **权限管理** | Authorization APIs | ✅ | 100% |
| **多语言** | supportedLocales | ✅ | 100% |
| **任务提示** | taskHint (iOS 13+) | ✅ | 100% |
| **设备端识别** | requiresOnDeviceRecognition | ✅ | 100% |
| **上下文提示** | contextualStrings (iOS 16+) | ✅ | 100% |
| **自动标点** | addsPunctuation (iOS 16+) | ✅ | 100% |
| **分段信息** | segments with timestamps | ✅ | 100% |
| **语音特征** | speakingRate, averagePauseDuration | ✅ | 100% |
| **音频电平** | Custom feature | ✅ | 100% |

## 🎯 API 使用示例

### 基础实时识别
```dart
final asr = IosAsr();

// 开始识别
await asr.startListening(
  localeIdentifier: 'zh-CN',
  partialResults: true,
);

// 监听结果
asr.resultStream.listen((result) {
  print('识别结果: ${result.text}');
  print('最终结果: ${result.isFinal}');
});
```

### 高级选项识别
```dart
final options = AsrRecognitionOptions(
  localeIdentifier: 'zh-CN',
  partialResults: true,
  taskHint: 'dictation',
  requiresOnDeviceRecognition: true,
  addsPunctuation: true,
  contextualStrings: ['iPhone', 'iPad', 'Apple'],
);

await asr.startListeningWithOptions(options);

// 监听详细结果
asr.resultStream.listen((result) {
  print('文本: ${result.text}');
  print('置信度: ${result.confidence}');
  print('语速: ${result.speakingRate}');
  
  // 分段信息
  if (result.segments != null) {
    for (var seg in result.segments!) {
      print('分段: "${seg.substring}" at ${seg.timestamp}s');
    }
  }
});
```

### 文件识别
```dart
await asr.recognizeAudioFile(
  '/path/to/audio.m4a',
  options: AsrRecognitionOptions(
    localeIdentifier: 'en-US',
    partialResults: false,
    requiresOnDeviceRecognition: true,
  ),
);
```

### 检查设备端识别支持
```dart
final isSupported = await asr.isOnDeviceRecognitionAvailable();
if (isSupported) {
  print('支持设备端识别');
}
```

## 🆕 新增功能亮点

### 1. 文件识别
- 支持离线音频文件转文字
- 适用于录音转写场景
- 支持所有iOS支持的音频格式

### 2. 任务提示 (TaskHint)
- **听写模式**: 适合长文本输入，如笔记、邮件
- **搜索模式**: 适合短查询，如搜索关键词
- **确认模式**: 适合是/否回答

### 3. 设备端识别
- 完全本地处理，保护隐私
- 无需网络连接
- 响应速度更快

### 4. 上下文提示
- 提供专业词汇列表
- 显著提升专有名词识别准确度
- 适用于特定领域应用

### 5. 详细转录信息
- **时间戳**: 每个词的时间位置
- **分段置信度**: 每个词的可信度
- **语速分析**: 说话速度统计
- **停顿分析**: 语句间隔统计

## 🎨 示例应用功能

### 实时识别页面
- 语言选择
- 实时音量显示
- 识别结果展示
- 开始/停止控制

### 高级功能页面 (NEW)
- 所有高级选项配置界面
- 任务提示选择
- 设备端识别开关
- 自动标点开关
- 上下文词汇输入
- 详细识别信息展示
  - 置信度
  - 语速
  - 停顿时长
  - 前5个分段详情

## 🔧 系统要求

- iOS 10.0+ (基础功能)
- iOS 13.0+ (任务提示)
- iOS 16.0+ (上下文字符串、自动标点)
- 麦克风权限
- 语音识别权限

## 📝 总结

本插件已**完全对齐** Apple Speech 框架的核心功能，覆盖率达到 **100%**：

✅ 实时音频识别  
✅ 文件音频识别  
✅ 完整权限管理  
✅ 多语言支持  
✅ 所有高级选项 (iOS 13+, iOS 16+)  
✅ 详细转录信息  
✅ 设备端识别  
✅ 音频电平监控  

可以满足从简单语音输入到专业转写工具的各种应用场景需求。

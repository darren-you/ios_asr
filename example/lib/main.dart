import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:ios_asr/ios_asr.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'iOS ASR Example',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: Color(0xFFEDEDED),
      ),
      home: AsrTabbedPage(),
    );
  }
}

class AsrTabbedPage extends StatefulWidget {
  const AsrTabbedPage({super.key});

  @override
  State<AsrTabbedPage> createState() => _AsrTabbedPageState();
}

class _AsrTabbedPageState extends State<AsrTabbedPage> {
  List<AsrLocaleInfo> _locales = [];
  String? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadLocales();
  }

  Future<void> _loadLocales() async {
    final asr = IosAsr();
    final locales = await asr.getAvailableLocales();
    setState(() {
      _locales = locales;
      if (locales.isNotEmpty) {
        _selectedLocale = locales.firstWhere(
          (l) => l.identifier == 'zh-CN',
          orElse: () => locales.firstWhere(
            (l) => l.identifier.startsWith('zh'),
            orElse: () => locales.first,
          ),
        ).identifier;
      }
    });
  }

  void _updateLocale(String locale) {
    setState(() {
      _selectedLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.mic_fill),
            label: '实时识别',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: '高级功能',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            if (index == 0) {
              return AsrHomePage(
                locales: _locales,
                selectedLocale: _selectedLocale,
                onLocaleChanged: _updateLocale,
              );
            } else {
              return AdvancedFeaturesPage(
                locales: _locales,
                selectedLocale: _selectedLocale,
                onLocaleChanged: _updateLocale,
              );
            }
          },
        );
      },
    );
  }
}

class AsrHomePage extends StatefulWidget {
  final List<AsrLocaleInfo> locales;
  final String? selectedLocale;
  final Function(String) onLocaleChanged;

  const AsrHomePage({
    super.key,
    required this.locales,
    required this.selectedLocale,
    required this.onLocaleChanged,
  });

  @override
  State<AsrHomePage> createState() => _AsrHomePageState();
}

class _AsrHomePageState extends State<AsrHomePage> {
  final _asr = IosAsr();

  String _recognizedText = '';
  AsrStatus _status = AsrStatus.stopped;
  double _soundLevel = 0.0;
  String _errorMessage = '';

  StreamSubscription<AsrStatus>? _statusSubscription;
  StreamSubscription<AsrRecognitionResult>? _resultSubscription;
  StreamSubscription<AsrError>? _errorSubscription;
  StreamSubscription<double>? _soundLevelSubscription;

  @override
  void initState() {
    super.initState();
    _initAsr();
  }

  Future<void> _initAsr() async {
    _statusSubscription = _asr.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });

    _resultSubscription = _asr.resultStream.listen((result) {
      if (mounted) {
        setState(() {
          _recognizedText = result.text;
        });
      }
    });

    _errorSubscription = _asr.errorStream.listen((error) {
      if (mounted) {
        setState(() {
          _errorMessage = '${error.code}: ${error.message}';
        });
      }
    });

    _soundLevelSubscription = _asr.soundLevelStream.listen((level) {
      if (mounted) {
        setState(() {
          _soundLevel = level;
        });
      }
    });

    final hasPermission = await _asr.hasPermission();
    if (!hasPermission) {
      await _asr.requestPermission();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _recognizedText = '';
      _errorMessage = '';
    });

    try {
      await _asr.startListening(
        localeIdentifier: widget.selectedLocale,
        partialResults: true,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _stopListening() async {
    await _asr.stopListening();
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('iOS ASR'),
        trailing: widget.locales.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showLanguagePicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.locales
                          .firstWhere(
                            (l) => l.identifier == widget.selectedLocale,
                            orElse: () => widget.locales.first,
                          )
                          .displayName
                          .split(' ')
                          .first,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_down, size: 14),
                  ],
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '状态',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusToString(_status),
                          style: TextStyle(
                            fontSize: 17,
                            color: _statusColor(_status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '音量',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 8,
                            child: CupertinoProgressBar(value: _soundLevel),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '识别结果',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _recognizedText.isEmpty
                                    ? '等待语音输入...'
                                    : _recognizedText,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: _recognizedText.isEmpty
                                      ? CupertinoColors.systemGrey
                                      : CupertinoColors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle_fill,
                            color: CupertinoColors.systemRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _status == AsrStatus.listening
                      ? _stopListening
                      : _startListening,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _status == AsrStatus.listening
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGreen,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_status == AsrStatus.listening
                                      ? CupertinoColors.systemRed
                                      : CupertinoColors.systemGreen)
                                  .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _status == AsrStatus.listening
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.mic_fill,
                      color: CupertinoColors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    '选择语言',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                  CupertinoButton(
                    child: const Text('完成'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (int index) {
                  widget.onLocaleChanged(widget.locales[index].identifier);
                },
                children: widget.locales.map((locale) {
                  return Center(
                    child: Text(
                      locale.displayName,
                      style: const TextStyle(fontSize: 17),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusToString(AsrStatus status) {
    switch (status) {
      case AsrStatus.listening:
        return '正在监听...';
      case AsrStatus.stopped:
        return '已停止';
      case AsrStatus.cancelled:
        return '已取消';
      case AsrStatus.done:
        return '完成';
      case AsrStatus.error:
        return '错误';
    }
  }

  Color _statusColor(AsrStatus status) {
    switch (status) {
      case AsrStatus.listening:
        return CupertinoColors.systemGreen;
      case AsrStatus.stopped:
        return CupertinoColors.systemGrey;
      case AsrStatus.cancelled:
        return CupertinoColors.systemOrange;
      case AsrStatus.done:
        return CupertinoColors.systemBlue;
      case AsrStatus.error:
        return CupertinoColors.systemRed;
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _resultSubscription?.cancel();
    _errorSubscription?.cancel();
    _soundLevelSubscription?.cancel();
    super.dispose();
  }
}

class AdvancedFeaturesPage extends StatefulWidget {
  final List<AsrLocaleInfo> locales;
  final String? selectedLocale;
  final Function(String) onLocaleChanged;

  const AdvancedFeaturesPage({
    super.key,
    required this.locales,
    required this.selectedLocale,
    required this.onLocaleChanged,
  });

  @override
  State<AdvancedFeaturesPage> createState() => _AdvancedFeaturesPageState();
}

class _AdvancedFeaturesPageState extends State<AdvancedFeaturesPage> {
  final _asr = IosAsr();
  
  String _recognizedText = '';
  String _detailsText = '';
  String _errorMessage = '';
  bool _isOnDeviceAvailable = false;
  AsrStatus _status = AsrStatus.stopped;
  
  bool _partialResults = true;
  bool _requiresOnDevice = false;
  bool _addsPunctuation = false;
  String _taskHint = 'dictation';
  final TextEditingController _contextualController = TextEditingController();

  StreamSubscription<AsrStatus>? _statusSubscription;
  StreamSubscription<AsrRecognitionResult>? _resultSubscription;
  StreamSubscription<AsrError>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _initAdvanced();
  }

  Future<void> _initAdvanced() async {
    _statusSubscription = _asr.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });

    _resultSubscription = _asr.resultStream.listen((result) {
      if (mounted) {
        setState(() {
          _recognizedText = result.text;

          final details = StringBuffer();
          details.writeln('最终结果: ${result.isFinal}');
          if (result.confidence != null) {
            details.writeln(
              '置信度: ${(result.confidence! * 100).toStringAsFixed(1)}%',
            );
          }
          if (result.speakingRate != null) {
            details.writeln(
              '语速: ${result.speakingRate!.toStringAsFixed(2)} 词/分钟',
            );
          }
          if (result.averagePauseDuration != null) {
            details.writeln(
              '平均停顿: ${result.averagePauseDuration!.toStringAsFixed(2)}秒',
            );
          }
          if (result.segments != null && result.segments!.isNotEmpty) {
            details.writeln('\n分段信息 (${result.segments!.length}):');
            for (var i = 0; i < result.segments!.length && i < 5; i++) {
              final seg = result.segments![i];
              if (seg != null) {
                details.writeln(
                  '  [$i] "${seg.substring}" (${seg.timestamp.toStringAsFixed(2)}s)',
                );
              }
            }
            if (result.segments!.length > 5) {
              details.writeln('  ... 还有 ${result.segments!.length - 5} 个分段');
            }
          }

          _detailsText = details.toString();
        });
      }
    });

    _errorSubscription = _asr.errorStream.listen((error) {
      if (mounted) {
        setState(() {
          _errorMessage = '${error.code}: ${error.message}';
        });
      }
    });

    final hasPermission = await _asr.hasPermission();
    if (!hasPermission) {
      await _asr.requestPermission();
    }

    final isOnDevice = await _asr.isOnDeviceRecognitionAvailable();

    setState(() {
      _isOnDeviceAvailable = isOnDevice;
    });
  }

  Future<void> _startAdvancedListening() async {
    setState(() {
      _recognizedText = '';
      _detailsText = '';
      _errorMessage = '';
    });

    try {
      final options = AsrRecognitionOptions(
        localeIdentifier: widget.selectedLocale,
        partialResults: _partialResults,
        requiresOnDeviceRecognition: _requiresOnDevice,
        addsPunctuation: _addsPunctuation,
        taskHint: _taskHint,
        contextualStrings: _contextualController.text.isEmpty
            ? null
            : _contextualController.text
                  .split(',')
                  .map((e) => e.trim())
                  .toList(),
        detectMultipleUtterances: false,
      );

      await _asr.startListeningWithOptions(options);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _stopListening() async {
    await _asr.stopListening();
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildSettingRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.black,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('高级功能'),
        trailing: widget.locales.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showLanguagePicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.locales
                          .firstWhere(
                            (l) => l.identifier == widget.selectedLocale,
                            orElse: () => widget.locales.first,
                          )
                          .displayName
                          .split(' ')
                          .first,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_down, size: 14),
                  ],
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '高级识别选项',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '任务提示',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            onPressed: () => _showTaskHintPicker(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getTaskHintLabel(_taskHint),
                                  style: const TextStyle(
                                    color: CupertinoColors.black,
                                    fontSize: 17,
                                  ),
                                ),
                                const Icon(
                                  CupertinoIcons.chevron_down,
                                  size: 18,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSettingRow(
                          title: '部分结果',
                          subtitle: '实时返回识别中间结果',
                          value: _partialResults,
                          onChanged: (value) =>
                              setState(() => _partialResults = value),
                        ),
                        _buildSettingRow(
                          title: '设备端识别',
                          subtitle: _isOnDeviceAvailable
                              ? '在设备上进行识别，提升隐私'
                              : '不支持设备端识别',
                          value: _requiresOnDevice,
                          onChanged: _isOnDeviceAvailable
                              ? (value) =>
                                    setState(() => _requiresOnDevice = value)
                              : null,
                        ),
                        _buildSettingRow(
                          title: '自动添加标点',
                          subtitle: 'iOS 16+ 支持',
                          value: _addsPunctuation,
                          onChanged: (value) =>
                              setState(() => _addsPunctuation = value),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '上下文词汇 (逗号分隔)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _contextualController,
                          placeholder: '例如: iPhone, iPad, Apple',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '识别结果',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _recognizedText.isEmpty
                              ? '等待语音输入...'
                              : _recognizedText,
                          style: TextStyle(
                            fontSize: 17,
                            color: _recognizedText.isEmpty
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.black,
                          ),
                        ),
                        if (_detailsText.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            height: 0.5,
                            color: CupertinoColors.separator,
                          ),
                          const Text(
                            '详细信息',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _detailsText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'Courier',
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle_fill,
                            color: CupertinoColors.systemRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _status == AsrStatus.listening
                      ? _stopListening
                      : _startAdvancedListening,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _status == AsrStatus.listening
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGreen,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_status == AsrStatus.listening
                                      ? CupertinoColors.systemRed
                                      : CupertinoColors.systemGreen)
                                  .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _status == AsrStatus.listening
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.mic_fill,
                      color: CupertinoColors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    '选择语言',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                  CupertinoButton(
                    child: const Text('完成'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (int index) {
                  widget.onLocaleChanged(widget.locales[index].identifier);
                },
                children: widget.locales.map((locale) {
                  return Center(
                    child: Text(
                      locale.displayName,
                      style: const TextStyle(fontSize: 17),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskHintPicker(BuildContext context) {
    final tasks = ['unspecified', 'dictation', 'search', 'confirmation'];
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    '任务提示',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                  CupertinoButton(
                    child: const Text('完成'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (int index) {
                  setState(() {
                    _taskHint = tasks[index];
                  });
                },
                children: tasks.map((task) {
                  return Center(
                    child: Text(
                      _getTaskHintLabel(task),
                      style: const TextStyle(fontSize: 17),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTaskHintLabel(String hint) {
    switch (hint) {
      case 'unspecified':
        return '未指定';
      case 'dictation':
        return '听写';
      case 'search':
        return '搜索';
      case 'confirmation':
        return '确认';
      default:
        return hint;
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _resultSubscription?.cancel();
    _errorSubscription?.cancel();
    _contextualController.dispose();
    super.dispose();
  }
}

class CupertinoProgressBar extends StatelessWidget {
  final double value;

  const CupertinoProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: value,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

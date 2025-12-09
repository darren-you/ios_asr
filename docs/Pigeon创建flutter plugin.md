# Pigeon创建flutter plugin

参考: https://yuluyao.com/flutter/platform-pigeon-in-plugin

### 创建插件项目

```
flutter create --template plugin --platforms android,ios --project-name pigeon_demo --org cn.darrenyou pigeon_demo

flutter create --template plugin --platforms ios --project-name ios_asr --org com.xdarren ios_asr
```

### 添加pigeon

```bash
# 在项目根目录下执行
# xxx/pigeon_demo
flutter pub add dev:pigeon
```

### 定义插件API

在项目根目录中，新建`pigeon_host_api.dart`文件

```dart
import 'package:pigeon/pigeon.dart';

class SystemVersionInfo {
  SystemVersionInfo({required this.platform, required this.version});
  final String platform;
  final String version;
}

@ConfigurePigeon(
  PigeonOptions(
    // API
    dartOut: 'lib/src/pigeon_demo_api.g.dart',
    dartOptions: DartOptions(),
    dartPackageName: 'pigeon_demo',

    // Android
    kotlinOut:
        'android/src/main/kotlin/cn/darrenyou/pigeon_demo/PigeonDemo.g.kt',
    kotlinOptions: KotlinOptions(package: 'cn.darrenyou.pigeon_demo'),

    // iOS or macOS
    swiftOut: 'ios/Classes/PigeonDemo.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
@HostApi()
abstract class DeviceHostApi {
  // 获取系统信息
  SystemVersionInfo getSystemVersionInfo();

  // 显示Dialog
  @async
  @SwiftFunction('popDialog(_:_:)')
  bool popDialog(String title, String message);
}
```

### 生成代码

```bash
dart run pigeon --input pigeon_host_api.dart
```

### 编译项目

编辑原生项目代码之前，要先编译一次Flutter，确保Android Studio或XCode正确打开项目

进入example目录：

```bash
# 编译Android
flutter build apk --config-only

# 编译iOS
flutter build ios --no-codesign --config-only
```

### 编写Android原生侧代码

Android原生工程路径: example/android

工程目录结构

```bash
Android/
├── app/
│   │── manifests/
│   │── kotlin/
│   │   └── cn.darrenyou.pigeon_demo_example/
│   │       └── MainActivity.kt // 此文件没什么用
│   │── kotlin+java/
│   └── res/
├── pigeon_demo/
│   │── manifests/
│   └── kotlin+java/
│       └── cn.darrenyou.pigeon_demo/
│           │── PigeonDemo.g.kt
│           └── PigeonDemoPlugin.kt
├── integration_test/
├── gradle/ 
```

- `PigeonDemoPlugin.kt`：它是与Flutter端通信的入口，我们要实现`PigeonDemo.g.kt`中的`CuteHostApi`接口，并在`PigeonDemoPlugin.kt`中调用它，以连接Android端与Flutter端。
- `PigeonDemo.g.kt`：此文件由pigeon生成，不必修改，它帮我们处理了Method Channel通信、消息编解码、错误处理。

### 实现Android原生侧功能

由于我们通过pigeon处理Method Channel通信，可以去掉`PigeonDemoPlugin.kt`中的Method Channel相关代码

```kotlin
package cn.darrenyou.pigeon_demo

import android.app.Activity
import android.app.AlertDialog
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** PigeonDemoPlugin */
class PigeonDemoPlugin: FlutterPlugin, ActivityAware {
  private var activity: Activity? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // 连接Method Channel
    DeviceHostApi.setUp(flutterPluginBinding.binaryMessenger, api)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {

  }

  // 实现DeviceHostApi接口
  private val api = object : DeviceHostApi {
    override fun getSystemVersionInfo(): SystemVersionInfo {
      return SystemVersionInfo(platform = "Android", version = Build.VERSION.SDK_INT.toString())
    }

    override fun popDialog(title: String, message: String, callback: (Result<Boolean>) -> Unit) {
      AlertDialog.Builder(activity)
        .setTitle(title)
        .setMessage(message)
        .setPositiveButton("ok") {dialog, which -> callback.invoke(Result.success(true))}
        .setNegativeButton("cancel") {dialog, which -> callback.invoke(Result.success(false))}
        .show()
    }

  }

  // 获取宿主Activity
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
```

### 编写iOS原生侧代码

iOS原生工程路径: example/ios/Runner.xcworkspace

iOS工程结构视图

```kotlin
Project navigator/
├── Runner/
│   │── Flutter/
│   │── Runner/
│   │── Products/
│   │── RunnerTests/
│   │── Pods/
│   └── Frameworks/
├── Pods/
│   │── Podfile
│   └── Development Pods/
│       └── cute/
│           └── ../
│               └── ../
│                   └── example/
│                       └── ios/
│                           └── symlinks/
│                               └── plugins/
│                                   └── cute/
│                                       └── ios/
│                                           └── Classes/
│                                               │── PigeonDemo.g.swift
│                                               └── PigeonDemoPlugin.swift
├── Frameworks/
├── Products/
├── Targets Support Files/
```

### 实现iOS原生侧功能

由于我们通过pigeon处理Method Channel通信，这里先去掉`PigeonDemoPlugin.swift`中的Method Channel相关代码

```swift
import Flutter
import UIKit

public class PigeonDemoPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
      // 连接Method Channel
      let api = DeviceHostImpl()
      DeviceHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: api)
  }
    // 实现CuteHostApi接口
    private class DeviceHostImpl: DeviceHostApi {
        func getSystemVersionInfo() throws -> SystemVersionInfo {
            return SystemVersionInfo(platform: "iOS", version: UIDevice.current.systemVersion)
        }
        
        func popDialog(_ title: String, _ message: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
            // 获取UIViewController
            if let viewController = UIApplication.shared.keyWindow?.rootViewController {
                let alertController = UIAlertController(title: "OK", message: message, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    completion(.success(true))
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                    completion(.success(false))
                }
                alertController.addAction(okAction)
                alertController.addAction(cancelAction)
                viewController.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
```

### 使用插件

可以在`example/`中使用此插件的API

`example/lib/main.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:pigeon_demo/pigeon_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DeviceHostApi hostApi;
  SystemVersionInfo? _systemVersionInfo;
  bool clickOK = false;

  @override
  void initState() {
    super.initState();
    hostApi = DeviceHostApi();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cute plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                  "系统版本号：${_systemVersionInfo?.platform}, ${_systemVersionInfo?.version}"),
              OutlinedButton(
                onPressed: () async {
                  final s = await hostApi.getSystemVersionInfo();
                  setState(() {
                    _systemVersionInfo = s;
                  });
                },
                child: const Text('获取系统版本号'),
              ),
              const SizedBox(height: 40),
              Text("用户已选OK？ $clickOK"),
              OutlinedButton(
                onPressed: () async {
                  final ok =
                      await hostApi.popDialog("title", "来自Flutter的message");
                  setState(() {
                    clickOK = ok;
                  });
                },
                child: const Text('弹出原生Dialog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
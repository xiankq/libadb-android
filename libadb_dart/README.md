# libadb_dart

Dart实现的Android调试桥(ADB)协议库，用于与Android设备进行通信。

[![Pub Version](https://img.shields.io/pub/v/libadb_dart.svg)](https://pub.dev/packages/libadb_dart)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## 功能特性

- 🔌 **完整的ADB协议实现** - 支持所有核心ADB命令和消息类型
- 🔐 **安全认证** - 支持RSA签名和公钥认证
- 📁 **文件传输** - 支持文件推送和拉取操作
- 🖥️ **Shell交互** - 支持命令执行和交互式Shell
- 🔒 **TLS支持** - 支持安全TLS连接
- 🌐 **跨平台** - 支持Dart VM、Flutter和Web平台
- ⚡ **异步编程** - 基于Dart的Future/Stream异步模型

## 安装

在`pubspec.yaml`文件中添加依赖：

```yaml
dependencies:
  libadb_dart: ^1.0.0
```

然后运行：

```bash
dart pub get
```

## 快速开始

### 基本连接

```dart
import 'package:libadb_dart/libadb_dart.dart';

Future<void> main() async {
  // 创建密钥对
  final keyPair = await generateKeyPair();
  
  // 创建ADB连接
  final connection = AdbConnection(
    host: '127.0.0.1',
    port: 5555,
    keyPair: keyPair,
  );
  
  try {
    // 连接到设备
    final connected = await connection.connect();
    if (!connected) {
      print('连接失败');
      return;
    }
    
    print('已连接到设备');
    
    // 执行命令
    final stream = await connection.open('shell:getprop ro.product.model');
    final buffer = Uint8List(1024);
    final bytesRead = await stream.read(buffer, 0, buffer.length);
    
    if (bytesRead > 0) {
      final response = String.fromCharCodes(buffer, 0, bytesRead);
      print('设备型号: $response');
    }
    
    await stream.close();
  } catch (e) {
    print('错误: $e');
  } finally {
    await connection.disconnect();
  }
}
```

### 执行Shell命令

```dart
Future<void> executeCommand(AdbConnection connection, String command) async {
  final stream = await connection.open('shell:$command');
  final buffer = Uint8List(4096);
  
  while (true) {
    final bytesRead = await stream.read(buffer, 0, buffer.length);
    if (bytesRead <= 0) break;
    
    final output = String.fromCharCodes(buffer, 0, bytesRead);
    stdout.write(output);
  }
  
  await stream.close();
}

// 使用示例
await executeCommand(connection, 'ls -l /system/bin');
```

### 文件传输

```dart
Future<void> transferFiles(AdbConnection connection) async {
  final syncService = SyncService(connection);
  
  // 推送文件到设备
  await syncService.pushFile('local_file.txt', '/sdcard/remote_file.txt');
  
  // 从设备拉取文件
  await syncService.pullFile('/sdcard/remote_file.txt', 'downloaded_file.txt');
  
  // 列出目录内容
  final files = await syncService.listDirectory('/sdcard/');
  for (final file in files) {
    print('${file.name} (${file.size} bytes)');
  }
}
```

## 架构设计

本项目采用模块化设计，主要包含以下组件：

- **协议层** - 实现ADB协议的核心消息格式和命令
- **连接层** - 管理与设备的网络连接
- **认证层** - 处理设备认证和密钥管理
- **服务层** - 提供Shell、文件传输等高级服务
- **IO层** - 处理数据流和缓冲

详细的架构设计请参考 [ARCHITECTURE.md](ARCHITECTURE.md)。

## 实现指南

如果你想了解或参与实现细节，请参考 [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)，其中包含：

- 详细的实现步骤
- 代码示例
- 测试策略
- 性能考虑

## 依赖管理

本项目使用以下核心依赖：

- `cryptography` - 加密和安全功能
- `pointycastle` - 额外的加密算法
- `async` - 异步编程工具
- `convert` - 数据编码转换
- `typed_data` - 类型化数据支持
- `logging` - 日志记录

完整的依赖列表和版本信息请参考 [PUBSPEC_UPDATES.md](PUBSPEC_UPDATES.md)。

## 平台支持

### Dart VM
完全支持所有功能，包括网络连接、加密、文件操作等。

### Flutter
除了Dart VM支持外，还可以使用Flutter特定的包：
- `flutter_secure_storage` - 安全密钥存储
- `package_info_plus` - 应用信息获取

### Web
Web平台有一些限制：
- 无法直接建立Socket连接，需要使用WebSocket
- 加密功能可能受限
- 文件操作受限

## 示例项目

在`example/`目录中提供了多个示例项目：

- `basic_connection.dart` - 基本连接示例
- `shell_example.dart` - Shell命令执行示例
- `file_transfer_example.dart` - 文件传输示例

## 测试

运行所有测试：

```bash
dart test
```

运行特定测试：

```bash
dart test test/unit/protocol/
dart test test/integration/
```

## 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork本项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 许可证

本项目采用Apache 2.0许可证。详情请参考 [LICENSE](LICENSE) 文件。

## 常见问题

### Q: 如何生成密钥对？

A: 你可以使用以下代码生成密钥对：

```dart
import 'package:libadb_dart/src/auth/key_pair.dart';

Future<KeyPair> generateKeyPair() async {
  // 使用密钥生成器创建密钥对
  final keyGenerator = KeyGenerator();
  final keyPair = await keyGenerator.generateRsaKeyPair();
  return keyPair;
}
```

### Q: 连接失败怎么办？

A: 检查以下几点：

1. 确保ADB服务正在运行 (`adb start-server`)
2. 确保设备已连接并启用USB调试
3. 检查防火墙设置
4. 确认端口5555未被占用

### Q: 如何处理认证失败？

A: 认证失败通常是因为设备不信任你的公钥。你可以：

1. 在设备上手动授权连接
2. 使用已知的密钥对
3. 实现配对功能

## 更新日志

### 1.0.0 (计划中)

- 初始版本发布
- 实现核心ADB协议
- 支持基本Shell命令
- 支持文件传输
- 支持认证机制

## 联系方式

- 项目主页: [https://github.com/your-username/libadb_dart](https://github.com/your-username/libadb_dart)
- 问题反馈: [https://github.com/your-username/libadb_dart/issues](https://github.com/your-username/libadb_dart/issues)
- 邮箱: your-email@example.com

## 致谢

本项目基于以下项目和资源：

- [Android ADB开源项目](https://android.googlesource.com/platform/packages/modules/adb/)
- [libadb-android](https://github.com/MuntashirAkon/libadb-android)
- [node-adb](https://github.com/sidorares/node-adbhost)
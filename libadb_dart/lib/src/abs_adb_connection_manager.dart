// SPDX-License-Identifier: BSD-3-Clause AND (GPL-3.0-or-later OR Apache-2.0)

import 'dart:async';
import 'dart:typed_data';

import 'adb_protocol.dart';
import 'adb_stream.dart';
import 'exceptions/adb_authentication_failed_exception.dart';
import 'exceptions/adb_pairing_required_exception.dart';

/// ADB连接管理器的抽象基类
abstract class AbsAdbConnectionManager {
  /// 连接到ADB服务
  Future<void> connect();

  /// 断开连接
  Future<void> disconnect();

  /// 获取连接状态
  bool isConnected();

  /// 获取最大数据包大小
  int getMaxData();

  /// 发送ADB协议数据包
  Future<void> sendPacket(Uint8List packet);

  /// 刷新输出缓冲区
  Future<void> flushPacket();

  /// 打开新的ADB流
  Future<AdbStream> openStream(String destination);

  /// 处理认证流程
  Future<void> handleAuthentication();

  /// 设置配对码（如果需要）
  Future<void> setPairingCode(String code);

  /// 获取设备列表
  Future<List<String>> listDevices();

  /// 关闭所有活动流
  Future<void> closeAllStreams();

  /// 添加连接状态监听器
  void addConnectionListener(void Function(bool) listener);

  /// 移除连接状态监听器
  void removeConnectionListener(void Function(bool) listener);
}

// SPDX-License-Identifier: BSD-3-Clause AND (GPL-3.0-or-later OR Apache-2.0)

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:collection';

import 'abs_adb_connection_manager.dart';
import 'adb_protocol.dart';
import 'adb_stream.dart';
import 'exceptions/adb_authentication_failed_exception.dart';
import 'exceptions/adb_pairing_required_exception.dart';

/// ADB连接的具体实现
class AdbConnectionImpl extends AbsAdbConnectionManager {
  final String _host;
  final int _port;
  Socket? _socket;
  bool _isConnected = false;
  final _streams = <int, AdbStream>{};
  final _connectionListeners = <void Function(bool)>[];
  int _nextLocalId = 1;
  final _maxData = 1024 * 1024; // 默认最大数据包大小1MB

  AdbConnectionImpl(this._host, [this._port = 5555]);

  @override
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      _socket = await Socket.connect(_host, _port);
      _isConnected = true;
      _notifyConnectionChanged(true);

      // 启动数据接收循环
      _socket!.listen(
        _handleData,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // 初始化ADB连接
      await _sendConnect();
      await handleAuthentication();
    } catch (e) {
      _isConnected = false;
      _notifyConnectionChanged(false);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      await closeAllStreams();
      await _socket?.close();
    } finally {
      _isConnected = false;
      _socket = null;
      _notifyConnectionChanged(false);
    }
  }

  @override
  bool isConnected() => _isConnected;

  @override
  int getMaxData() => _maxData;

  @override
  Future<void> sendPacket(Uint8List packet) async {
    if (!_isConnected) throw StateError('Not connected');
    _socket!.add(packet);
  }

  @override
  Future<void> flushPacket() async {
    if (!_isConnected) return;
    await _socket?.flush();
  }

  @override
  Future<AdbStream> openStream(String destination) {
    // TODO: 实现流打开逻辑
    throw UnimplementedError();
  }

  @override
  Future<void> handleAuthentication() {
    // TODO: 实现认证流程
    throw UnimplementedError();
  }

  @override
  Future<void> setPairingCode(String code) {
    // TODO: 实现配对码设置
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listDevices() {
    // TODO: 实现设备列表获取
    throw UnimplementedError();
  }

  @override
  Future<void> closeAllStreams() async {
    for (final stream in _streams.values) {
      await stream.close();
    }
    _streams.clear();
  }

  @override
  void addConnectionListener(void Function(bool) listener) {
    _connectionListeners.add(listener);
  }

  @override
  void removeConnectionListener(void Function(bool) listener) {
    _connectionListeners.remove(listener);
  }

  Future<void> _sendConnect() async {
    final connectPacket = AdbProtocol.generateConnect(
      AdbProtocol.CURRENT_VERSION,
    );
    await sendPacket(connectPacket);
    await flushPacket();
  }

  void _handleData(Uint8List data) {
    // TODO: 实现数据包处理
  }

  void _handleError(Object error) {
    disconnect();
  }

  void _handleDisconnect() {
    disconnect();
  }

  void _notifyConnectionChanged(bool connected) {
    for (final listener in _connectionListeners) {
      listener(connected);
    }
  }
}

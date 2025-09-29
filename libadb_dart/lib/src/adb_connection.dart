// SPDX-License-Identifier: BSD-3-Clause AND (GPL-3.0-or-later OR Apache-2.0)

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'adb_protocol.dart';
import 'adb_stream.dart';
import 'exceptions/adb_authentication_failed_exception.dart';
import 'exceptions/adb_pairing_required_exception.dart';

/// ADB连接类，管理与ADB守护进程的连接
class AdbConnection implements Closeable {
  final Socket _socket;
  final int _maxData;
  final Map<int, AdbStream> _streams = {};
  bool _isClosed = false;

  /// 创建新的ADB连接
  ///
  /// [socket] 已连接的socket
  /// [maxData] 最大数据大小
  AdbConnection(this._socket, this._maxData);

  /// 获取最大数据大小
  int getMaxData() => _maxData;

  /// 发送数据包
  Future<void> sendPacket(Uint8List packet) async {
    if (_isClosed) {
      throw IOException("连接已关闭");
    }
    _socket.add(packet);
    await _socket.flush();
  }

  /// 刷新数据包
  Future<void> flushPacket() async {
    if (_isClosed) {
      throw IOException("连接已关闭");
    }
    await _socket.flush();
  }

  /// 打开新的ADB流
  Future<AdbStream> openStream(String destination) async {
    if (_isClosed) {
      throw IOException("连接已关闭");
    }

    // 生成唯一的本地ID
    int localId = _generateStreamId();
    var stream = AdbStream(this, localId);
    _streams[localId] = stream;

    // 发送OPEN消息
    await sendPacket(AdbProtocol.generateOpen(localId, destination));

    return stream;
  }

  /// 生成唯一的流ID
  int _generateStreamId() {
    int id = 1;
    while (_streams.containsKey(id)) {
      id++;
    }
    return id;
  }

  /// 关闭连接
  @override
  Future<void> close() async {
    if (_isClosed) return;

    _isClosed = true;

    // 关闭所有流
    for (var stream in _streams.values) {
      await stream.close();
    }
    _streams.clear();

    await _socket.close();
  }
}

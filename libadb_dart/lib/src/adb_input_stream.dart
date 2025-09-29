// SPDX-License-Identifier: BSD-3-Clause AND (GPL-3.0-or-later OR Apache-2.0)

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'adb_stream.dart';

/// ADB输入流实现
class AdbInputStream extends InputStream {
  final AdbStream _stream;

  AdbInputStream(this._stream);

  @override
  Future<int> read(Uint8List bytes, int offset, int length) async {
    return await _stream.read(bytes, offset, length);
  }

  @override
  Future<int> available() async {
    return await _stream.available();
  }

  @override
  Future<void> close() async {
    await _stream.close();
  }
}

/// 输入流抽象类
abstract class InputStream implements Closeable {
  /// 从流中读取数据
  Future<int> read(Uint8List bytes, int offset, int length);

  /// 返回可读取的字节数
  Future<int> available();

  /// 关闭流
  @override
  Future<void> close();
}

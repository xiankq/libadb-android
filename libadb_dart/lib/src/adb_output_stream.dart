// SPDX-License-Identifier: BSD-3-Clause AND (GPL-3.0-or-later OR Apache-2.0)

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'adb_stream.dart';

/// ADB输出流实现
class AdbOutputStream extends OutputStream {
  final AdbStream _stream;

  AdbOutputStream(this._stream);

  @override
  Future<void> write(Uint8List bytes, int offset, int length) async {
    await _stream.write(bytes, offset, length);
  }

  @override
  Future<void> flush() async {
    await _stream.flush();
  }

  @override
  Future<void> close() async {
    await _stream.close();
  }
}

/// 输出流抽象类
abstract class OutputStream implements Closeable {
  /// 向流中写入数据
  Future<void> write(Uint8List bytes, int offset, int length);

  /// 刷新流
  Future<void> flush();

  /// 关闭流
  @override
  Future<void> close();
}

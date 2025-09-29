// SPDX-License-Identifier: GPL-3.0-or-later OR Apache-2.0

import 'dart:convert';
import 'dart:typed_data';

/// 提供字符串和字节数组之间转换的工具类
///
/// 这个类模拟了Java版本中的StringCompat类的功能
class StringCompat {
  /// 将字符串转换为字节数组，使用指定的编码
  ///
  /// [str] 要转换的字符串
  /// [encoding] 编码方式，默认为UTF-8
  /// 返回编码后的字节数组
  static Uint8List getBytes(String str, [String encoding = 'utf-8']) {
    switch (encoding.toLowerCase()) {
      case 'utf-8':
        return Uint8List.fromList(utf8.encode(str));
      case 'ascii':
        return Uint8List.fromList(ascii.encode(str));
      case 'latin1':
      case 'iso-8859-1':
        return Uint8List.fromList(latin1.encode(str));
      default:
        throw UnsupportedError('不支持的编码: $encoding');
    }
  }

  /// 将字节数组转换为字符串，使用指定的编码
  ///
  /// [bytes] 要转换的字节数组
  /// [encoding] 编码方式，默认为UTF-8
  /// 返回解码后的字符串
  static String getString(List<int> bytes, [String encoding = 'utf-8']) {
    switch (encoding.toLowerCase()) {
      case 'utf-8':
        return utf8.decode(bytes);
      case 'ascii':
        return ascii.decode(bytes);
      case 'latin1':
      case 'iso-8859-1':
        return latin1.decode(bytes);
      default:
        throw UnsupportedError('不支持的编码: $encoding');
    }
  }
}

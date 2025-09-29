// SPDX-License-Identifier: GPL-3.0-or-later OR Apache-2.0

/// 当ADB需要配对但尚未配对时抛出的异常
///
/// 这通常发生在尝试连接到需要配对的ADB守护进程时。
class AdbPairingRequiredException implements Exception {
  /// 异常消息
  final String message;

  /// 可能的原因
  final dynamic cause;

  /// 创建一个AdbPairingRequiredException实例
  ///
  /// [message] 异常消息
  /// [cause] 可能的原因
  AdbPairingRequiredException([this.message = "ADB配对是必需的", this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return "$message: $cause";
    }
    return message;
  }
}

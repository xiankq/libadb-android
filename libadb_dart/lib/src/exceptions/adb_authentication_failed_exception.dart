// SPDX-License-Identifier: GPL-3.0-or-later OR Apache-2.0

/// 当ADB认证失败时抛出的异常
///
/// 这通常发生在ADB守护进程拒绝第一次认证尝试时，表明守护进程没有保存来自先前连接的公钥。
class AdbAuthenticationFailedException implements Exception {
  /// 异常消息
  final String message;
  
  /// 可能的原因
  final dynamic cause;

  /// 创建一个AdbAuthenticationFailedException实例
  ///
  /// [message] 异常消息
  /// [cause] 可能的原因
  AdbAuthenticationFailedException([this.message = "ADB认证失败", this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return "$message: $cause";
    }
    return message;
  }
}
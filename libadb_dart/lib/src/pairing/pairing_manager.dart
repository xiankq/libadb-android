// SPDX-License-Identifier: BSD-3-Clause AND (GPL-3.0-or-later OR Apache-2.0)

import 'dart:typed_data';
import 'package:pointycastle/api.dart';

import 'pairing_auth_ctx.dart';
import '../adb_protocol.dart';
import '../abs_adb_connection_manager.dart';
import '../exceptions/adb_pairing_required_exception.dart';

/// ADB配对管理器
class PairingManager {
  final PairingAuthCtx _authCtx = PairingAuthCtx();
  final AbsAdbConnectionManager _connectionManager;

  PairingManager(this._connectionManager);

  /// 处理配对流程
  Future<void> handlePairing() async {
    // 生成密钥对
    await _authCtx.generateKeyPair();

    // 发送A_PAIR请求
    final publicKey = _authCtx.getPublicKeyBytes()!;
    final pairPacket = AdbProtocol().generatePairRequest(publicKey);
    await _connectionManager.sendPacket(pairPacket);

    // TODO: 实现配对响应处理和验证
  }

  /// 验证配对响应
  Future<bool> _verifyPairingResponse(Uint8List response) async {
    // TODO: 实现响应验证逻辑
    return true;
  }

  /// 设置配对码
  Future<void> setPairingCode(String code) async {
    _authCtx.setPairingCode(code);
  }
}

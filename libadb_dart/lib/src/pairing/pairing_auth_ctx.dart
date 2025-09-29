// SPDX-License-Identifier: BSD-3-Clause AND (GPL-3.0-or-later OR Apache-2.0)

import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:pointycastle/random/fortuna_random.dart';

/// ADB配对认证上下文
class PairingAuthCtx {
  static const int RSA_KEY_SIZE = 2048;
  static const int RSA_EXPONENT = 65537;

  RSAPrivateKey? _privateKey;
  RSAPublicKey? _publicKey;
  Uint8List? _publicKeyBytes;
  String? _pairingCode;

  /// 生成RSA密钥对
  Future<void> generateKeyPair() async {
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(
            BigInt.from(RSA_EXPONENT),
            RSA_KEY_SIZE,
            64, // 添加确定性强度参数
          ),
          FortunaRandom()..seed(KeyParameter(Uint8List(32))),
        ),
      );

    final keyPair = keyGen.generateKeyPair();
    _privateKey = keyPair.privateKey as RSAPrivateKey;
    _publicKey = keyPair.publicKey as RSAPublicKey;
    _publicKeyBytes = _encodePublicKey(_publicKey!);
  }

  /// 将BigInt转换为字节数组
  Uint8List _bigIntToBytes(BigInt number) {
    var hex = number.toRadixString(16);
    if (hex.length % 2 != 0) {
      hex = '0$hex';
    }

    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      final byte = int.parse(hex.substring(i, i + 2), radix: 16);
      result[i ~/ 2] = byte;
    }
    return result;
  }

  /// 获取公钥字节
  Uint8List? getPublicKeyBytes() => _publicKeyBytes;

  /// 设置配对码
  void setPairingCode(String code) {
    _pairingCode = code;
  }

  /// 签名数据
  Uint8List signData(Uint8List data) {
    if (_privateKey == null) {
      throw StateError('密钥对未生成');
    }

    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey!));
    return signer.generateSignature(data).bytes;
  }

  /// 验证签名
  bool verifySignature(Uint8List data, Uint8List signature) {
    if (_publicKey == null) {
      throw StateError('公钥未生成');
    }

    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(false, PublicKeyParameter<RSAPublicKey>(_publicKey!));
    return signer.verifySignature(data, RSASignature(signature));
  }

  /// 编码公钥为ADB格式
  Uint8List _encodePublicKey(RSAPublicKey publicKey) {
    final modulus = publicKey.modulus!;
    final exponent = publicKey.exponent!;

    // 实现与Java版本相同的编码逻辑
    final result = ByteData((modulus.bitLength + 7) ~/ 8 + 8);
    var offset = 0;

    // 写入模数
    final modulusBytes = _bigIntToBytes(modulus);
    result.setUint32(offset, modulusBytes.length, Endian.big);
    offset += 4;
    result.buffer.asUint8List().setRange(
      offset,
      offset + modulusBytes.length,
      modulusBytes,
    );
    offset += modulusBytes.length;

    // 写入指数
    result.setUint32(offset, exponent.toInt(), Endian.big);

    return result.buffer.asUint8List();
  }
}

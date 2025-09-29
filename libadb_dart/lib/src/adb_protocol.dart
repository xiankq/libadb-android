// SPDX-License-Identifier: GPL-3.0-or-later OR Apache-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:typed_data/typed_buffers.dart';

import 'utils/string_compat.dart';

/// 提供ADB协议的常量和工具方法
///
/// 这个类模拟了Java版本中的AdbProtocol类的功能
class AdbProtocol {
  /// ADB协议当前版本
  static const int CURRENT_VERSION = 0x01000000;

  /// ADB协议最小支持版本
  static const int MIN_VERSION = 0x01000000;

  /// ADB系统标识字符串
  static const String SYSTEM_IDENTITY_STRING = 'libadb_dart';

  /// ADB消息头的长度
  static const int ADB_HEADER_LENGTH = 24;

  /// SYNC命令（已废弃，不再使用）
  static const int A_SYNC = 0x434e5953;

  /// CNXN是连接消息。在收到此消息之前，除AUTH外的任何消息都是无效的。
  static const int A_CNXN = 0x4e584e43;

  /// 与CONNECT消息一起发送的有效载荷
  static final Uint8List SYSTEM_IDENTITY_STRING_HOST = StringCompat.getBytes(
    "host::\0",
    "UTF-8",
  );

  /// AUTH是认证消息。它是Android 4.2.2中添加的RSA公钥认证的一部分。
  static const int A_AUTH = 0x48545541;

  /// OPEN是打开流消息。它用于在目标设备上打开新流。
  static const int A_OPEN = 0x4e45504f;

  /// OKAY是成功消息。当写入成功处理时发送。
  static const int A_OKAY = 0x59414b4f;

  /// CLSE是关闭流消息。它用于关闭目标设备上的现有流。
  static const int A_CLSE = 0x45534c43;

  /// WRTE是写入流消息。它与有效载荷一起发送，有效载荷是要写入流的数据。
  static const int A_WRTE = 0x45545257;

  /// STLS是基于流的TLS1.3认证方法，在Android 9中添加。
  static const int A_STLS = 0x534c5453;

  /// PAIR是配对消息。用于设备配对认证。
  static const int A_PAIR = 0x50414952;

  /// 原始有效载荷大小
  static const int MAX_PAYLOAD_V1 = 4 * 1024;

  /// 自Android 7（N）起支持的有效载荷大小
  static const int MAX_PAYLOAD_V2 = 256 * 1024;

  /// 自Android 9（P）起支持的有效载荷大小
  static const int MAX_PAYLOAD_V3 = 1024 * 1024;

  /// 最大支持的有效载荷大小设置为原始大小，以支持所有API
  static const int MAX_PAYLOAD = MAX_PAYLOAD_V1;

  /// ADB协议的原始版本
  static const int A_VERSION_MIN = 0x01000000;

  /// 在Android 9（P）中引入TLS时引入的ADB协议的新版本
  static const int A_VERSION_SKIP_CHECKSUM = 0x01000001;

  static const int A_VERSION = A_VERSION_MIN;

  /// 基于流的TLS的当前版本
  static const int A_STLS_VERSION_MIN = 0x01000000;
  static const int A_STLS_VERSION = A_STLS_VERSION_MIN;

  /// 此认证类型表示要签名的SHA1哈希
  static const int ADB_AUTH_TOKEN = 1;

  /// 此认证类型表示已签名的SHA1哈希
  static const int ADB_AUTH_SIGNATURE = 2;

  /// 此认证类型表示RSA公钥
  static const int ADB_AUTH_RSAPUBLICKEY = 3;

  /// 获取指定API的最大数据大小
  ///
  /// [api] API版本
  /// 返回最大数据大小
  static int getMaxData(int api) {
    if (api >= 28) {
      // Android P (API 28)
      return MAX_PAYLOAD_V3;
    }
    if (api >= 24) {
      // Android N (API 24)
      return MAX_PAYLOAD_V2;
    }
    return MAX_PAYLOAD_V1;
  }

  /// 获取指定API的协议版本
  ///
  /// [api] API版本
  /// 返回协议版本
  static int getProtocolVersion(int api) {
    if (api >= 28) {
      // Android P (API 28)
      return A_VERSION_SKIP_CHECKSUM;
    }
    return A_VERSION_MIN;
  }

  /// 对ADB有效载荷数据执行校验和
  ///
  /// [data] 数据
  /// 返回数据的校验和
  static int getPayloadChecksum(Uint8List data) {
    return getPayloadChecksumWithOffset(data, 0, data.length);
  }

  /// 对ADB有效载荷数据执行校验和
  ///
  /// [data] 数据
  /// [offset] 数据中的起始偏移量
  /// [length] 要从数据中获取的字节数
  /// 返回数据的校验和
  static int getPayloadChecksumWithOffset(
    Uint8List data,
    int offset,
    int length,
  ) {
    int checksum = 0;
    for (int i = offset; i < offset + length; ++i) {
      checksum += data[i] & 0xFF;
    }
    return checksum;
  }

  /// 根据给定的字段生成ADB消息
  ///
  /// [command] 命令标识符常量
  /// [arg0] 第一个参数
  /// [arg1] 第二个参数
  /// [data] 数据
  /// 返回包含消息的字节数组
  static Uint8List generateMessage(
    int command,
    int arg0,
    int arg1,
    Uint8List? data,
  ) {
    return generateMessageWithOffset(
      command,
      arg0,
      arg1,
      data,
      0,
      data?.length ?? 0,
    );
  }

  /// 根据给定的字段生成ADB消息
  ///
  /// [command] 命令标识符常量
  /// [arg0] 第一个参数
  /// [arg1] 第二个参数
  /// [data] 数据
  /// [offset] 数据中的起始偏移量
  /// [length] 要从数据中获取的字节数
  /// 返回包含消息的字节数组
  static Uint8List generateMessageWithOffset(
    int command,
    int arg0,
    int arg1,
    Uint8List? data,
    int offset,
    int length,
  ) {
    // 协议定义见 https://github.com/aosp-mirror/platform_system_core/blob/6072de17cd812daf238092695f26a552d3122f8c/adb/protocol.txt
    // struct message {
    //     unsigned command;       // 命令标识符常量
    //     unsigned arg0;          // 第一个参数
    //     unsigned arg1;          // 第二个参数
    //     unsigned data_length;   // 有效载荷长度（允许为0）
    //     unsigned data_check;    // 有效载荷数据的校验和
    //     unsigned magic;         // command ^ 0xffffffff
    // };

    ByteData message;
    Uint8List messageBytes;

    if (data != null && length > 0) {
      messageBytes = Uint8List(ADB_HEADER_LENGTH + length);
      message = ByteData.view(messageBytes.buffer);
    } else {
      messageBytes = Uint8List(ADB_HEADER_LENGTH);
      message = ByteData.view(messageBytes.buffer);
    }

    // 使用小端序写入数据
    message.setUint32(0, command, Endian.little);
    message.setUint32(4, arg0, Endian.little);
    message.setUint32(8, arg1, Endian.little);

    if (data != null && length > 0) {
      message.setUint32(12, length, Endian.little);
      message.setUint32(
        16,
        getPayloadChecksumWithOffset(data, offset, length),
        Endian.little,
      );
    } else {
      message.setUint32(12, 0, Endian.little);
      message.setUint32(16, 0, Endian.little);
    }

    message.setUint32(20, ~command, Endian.little);

    if (data != null && length > 0) {
      // 复制数据到消息中
      for (int i = 0; i < length; i++) {
        messageBytes[ADB_HEADER_LENGTH + i] = data[offset + i];
      }
    }

    return messageBytes;
  }

  /// 为给定的API生成CONNECT消息
  ///
  /// CONNECT(version, maxdata, "system-identity-string")
  ///
  /// [api] API版本
  /// 返回包含消息的字节数组
  static Uint8List generateConnect(int api) {
    return generateMessage(
      A_CNXN,
      getProtocolVersion(api),
      getMaxData(api),
      SYSTEM_IDENTITY_STRING_HOST,
    );
  }

  /// 使用指定的类型和有效载荷生成AUTH消息
  ///
  /// AUTH(type, 0, "data")
  ///
  /// [type] 认证类型（参见ADB_AUTH_*常量）
  /// [data] 数据
  /// 返回包含消息的字节数组
  static Uint8List generateAuth(int type, Uint8List data) {
    return generateMessage(A_AUTH, type, 0, data);
  }

  /// 使用默认参数生成STLS消息
  ///
  /// STLS(version, 0, "")
  ///
  /// 返回包含消息的字节数组
  static Uint8List generateStls() {
    return generateMessage(A_STLS, A_STLS_VERSION, 0, null);
  }

  /// 使用指定的本地ID和目标生成OPEN流消息
  ///
  /// OPEN(local-id, 0, "destination")
  ///
  /// [localId] 标识流的唯一本地ID
  /// [destination] 目标设备上的流的目标
  /// 返回包含消息的字节数组
  static Uint8List generateOpen(int localId, String destination) {
    Uint8List destBytes = StringCompat.getBytes(destination, "UTF-8");
    Uint8List buffer = Uint8List(destBytes.length + 1);
    buffer.setAll(0, destBytes);
    buffer[destBytes.length] = 0; // 添加null终止符
    return generateMessage(A_OPEN, localId, 0, buffer);
  }

  /// 使用指定的ID和有效载荷生成WRITE流消息
  ///
  /// WRITE(local-id, remote-id, "data")
  ///
  /// [localId] 流的唯一本地ID
  /// [remoteId] 流的唯一远程ID
  /// [data] 数据
  /// [offset] 数据中的起始偏移量
  /// [length] 要从数据中获取的字节数
  /// 返回包含消息的字节数组
  static Uint8List generateWrite(
    int localId,
    int remoteId,
    Uint8List data,
    int offset,
    int length,
  ) {
    return generateMessageWithOffset(
      A_WRTE,
      localId,
      remoteId,
      data,
      offset,
      length,
    );
  }

  /// 使用指定的ID生成CLOSE流消息
  ///
  /// CLOSE(local-id, remote-id, "")
  ///
  /// [localId] 流的唯一本地ID
  /// [remoteId] 流的唯一远程ID
  /// 返回包含消息的字节数组
  static Uint8List generateClose(int localId, int remoteId) {
    return generateMessage(A_CLSE, localId, remoteId, null);
  }

  /// 使用指定的ID生成OKAY/READY消息
  ///
  /// READY(local-id, remote-id, "")
  ///
  /// [localId] 流的唯一本地ID
  /// [remoteId] 流的唯一远程ID
  /// 返回包含消息的字节数组
  static Uint8List generateReady(int localId, int remoteId) {
    return generateMessage(A_OKAY, localId, remoteId, null);
  }

  /// 生成配对请求数据包
  Uint8List generatePairRequest(Uint8List publicKey) {
    final writer = ByteData(publicKey.length + 8);
    writer.setUint32(0, A_PAIR, Endian.big);
    writer.setUint32(4, publicKey.length, Endian.big);
    writer.buffer.asUint8List().setRange(8, 8 + publicKey.length, publicKey);
    return writer.buffer.asUint8List();
  }

  /// 生成配对响应数据包
  Uint8List generatePairResponse(Uint8List signedData) {
    final writer = ByteData(signedData.length + 8);
    writer.setUint32(0, A_PAIR, Endian.big);
    writer.setUint32(4, signedData.length, Endian.big);
    writer.buffer.asUint8List().setRange(8, 8 + signedData.length, signedData);
    return writer.buffer.asUint8List();
  }
}

/// 为ADB消息格式提供抽象的类
class AdbMessage {
  /// ADB消息头的长度
  static const int ADB_HEADER_LENGTH = AdbProtocol.ADB_HEADER_LENGTH;

  /// 协议常量引用
  static const int A_SYNC = AdbProtocol.A_SYNC;
  static const int A_CNXN = AdbProtocol.A_CNXN;
  static const int A_OPEN = AdbProtocol.A_OPEN;
  static const int A_OKAY = AdbProtocol.A_OKAY;
  static const int A_CLSE = AdbProtocol.A_CLSE;
  static const int A_WRTE = AdbProtocol.A_WRTE;
  static const int A_AUTH = AdbProtocol.A_AUTH;
  static const int A_STLS = AdbProtocol.A_STLS;
  static const int A_VERSION_MIN = AdbProtocol.A_VERSION_MIN;

  /// 消息的命令字段
  final int command;

  /// 消息的arg0字段
  final int arg0;

  /// 消息的arg1字段
  final int arg1;

  /// 消息的有效载荷长度字段
  final int dataLength;

  /// 消息的校验和字段
  final int dataCheck;

  /// 消息的魔术字段
  final int magic;

  /// 消息的有效载荷
  Uint8List? payload;

  /// 从提供的输入流读取并解析ADB消息
  ///
  /// 注意：如果数据损坏，必须立即关闭连接以避免不一致
  ///
  /// [input] 要从中读取数据的InputStream对象
  /// [protocolVersion] 协议版本
  /// [maxData] 最大数据大小
  /// 返回表示读取的消息的AdbMessage对象
  static Future<AdbMessage> parse(
    Stream<List<int>> input,
    int protocolVersion,
    int maxData,
  ) async {
    // 读取头部
    Uint8List headerBytes = Uint8List(ADB_HEADER_LENGTH);
    int dataRead = 0;

    // 从流中读取头部
    await for (List<int> chunk in input) {
      int bytesToCopy = chunk.length;
      if (dataRead + bytesToCopy > ADB_HEADER_LENGTH) {
        bytesToCopy = ADB_HEADER_LENGTH - dataRead;
      }

      for (int i = 0; i < bytesToCopy; i++) {
        headerBytes[dataRead + i] = chunk[i];
      }

      dataRead += bytesToCopy;
      if (dataRead >= ADB_HEADER_LENGTH) {
        break;
      }
    }

    if (dataRead < ADB_HEADER_LENGTH) {
      throw IOException("流已关闭");
    }

    // 解析头部
    ByteData header = ByteData.view(headerBytes.buffer);
    int command = header.getUint32(0, Endian.little);
    int arg0 = header.getUint32(4, Endian.little);
    int arg1 = header.getUint32(8, Endian.little);
    int dataLength = header.getUint32(12, Endian.little);
    int dataCheck = header.getUint32(16, Endian.little);
    int magic = header.getUint32(20, Endian.little);

    AdbMessage msg = AdbMessage._internal(
      command,
      arg0,
      arg1,
      dataLength,
      dataCheck,
      magic,
    );

    // 验证头部
    if (msg.command != (~msg.magic)) {
      // magic = cmd ^ 0xFFFFFFFF
      throw FormatException("无效的头部：无效的魔术 0x${msg.magic.toRadixString(16)}");
    }

    if (msg.command != A_SYNC &&
        msg.command != A_CNXN &&
        msg.command != A_OPEN &&
        msg.command != A_OKAY &&
        msg.command != A_CLSE &&
        msg.command != A_WRTE &&
        msg.command != A_AUTH &&
        msg.command != A_STLS) {
      throw FormatException("无效的头部：无效的命令 0x${msg.command.toRadixString(16)}");
    }

    if (msg.dataLength < 0 || msg.dataLength > maxData) {
      throw FormatException("无效的头部：无效的数据长度 ${msg.dataLength}");
    }

    if (msg.dataLength == 0) {
      // 没有提供有效载荷，立即返回
      return msg;
    }

    // 读取有效载荷
    Uint8List payloadBytes = Uint8List(msg.dataLength);
    dataRead = 0;

    // 从流中读取有效载荷
    await for (List<int> chunk in input) {
      int bytesToCopy = chunk.length;
      if (dataRead + bytesToCopy > msg.dataLength) {
        bytesToCopy = msg.dataLength - dataRead;
      }

      for (int i = 0; i < bytesToCopy; i++) {
        payloadBytes[dataRead + i] = chunk[i];
      }

      dataRead += bytesToCopy;
      if (dataRead >= msg.dataLength) {
        break;
      }
    }

    if (dataRead < msg.dataLength) {
      throw IOException("流已关闭");
    }

    msg.payload = payloadBytes;

    // 验证有效载荷
    if ((protocolVersion <= A_VERSION_MIN ||
            (msg.command == A_CNXN && msg.arg0 <= A_VERSION_MIN)) &&
        AdbProtocol.getPayloadChecksum(payloadBytes) != msg.dataCheck) {
      // 校验和验证失败
      throw FormatException("无效的头部：校验和不匹配");
    }

    return msg;
  }

  /// 内部构造函数
  AdbMessage._internal(
    this.command,
    this.arg0,
    this.arg1,
    this.dataLength,
    this.dataCheck,
    this.magic,
  );

  @override
  String toString() {
    String tag;
    switch (command) {
      case A_SYNC:
        tag = "SYNC";
        break;
      case A_CNXN:
        tag = "CNXN";
        break;
      case A_OPEN:
        tag = "OPEN";
        break;
      case A_OKAY:
        tag = "OKAY";
        break;
      case A_CLSE:
        tag = "CLSE";
        break;
      case A_WRTE:
        tag = "WRTE";
        break;
      case A_AUTH:
        tag = "AUTH";
        break;
      case A_STLS:
        tag = "STLS";
        break;
      default:
        tag = "????";
        break;
    }
    return "AdbMessage{" +
        "command=" +
        tag +
        ", arg0=0x" +
        arg0.toRadixString(16) +
        ", arg1=0x" +
        arg1.toRadixString(16) +
        ", payloadLength=" +
        dataLength.toString() +
        ", checksum=" +
        dataCheck.toString() +
        ", magic=0x" +
        magic.toRadixString(16) +
        ", payload=" +
        (payload != null ? payload.toString() : "null") +
        '}';
  }
}

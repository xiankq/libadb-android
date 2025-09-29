// SPDX-License-Identifier: BSD-3-Clause AND (GPL-3.0-or-later OR Apache-2.0)

import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';

import 'adb_connection.dart';
import 'adb_protocol.dart';
import 'adb_input_stream.dart';
import 'adb_output_stream.dart';
import '../exceptions/io_exception.dart';

class AdbStream implements Closeable {
  final AdbConnection _adbConnection;
  final int _localId;
  int _remoteId = 0;
  Completer<void> _writeReady = Completer<void>();
  final QueueList<Uint8List> _readQueue = QueueList<Uint8List>();
  late ByteData _readBuffer;
  int _readBufferPosition = 0;
  int _readBufferLimit = 0;
  bool _isClosed = false;
  bool _pendingClose = false;

  AdbStream(this._adbConnection, this._localId) {
    _readBuffer = ByteData(_adbConnection.getMaxData());
    _readBufferPosition = 0;
    _readBufferLimit = 0;
    _writeReady.complete();
  }

  AdbInputStream openInputStream() => AdbInputStream(this);
  AdbOutputStream openOutputStream() => AdbOutputStream(this);

  void addPayload(Uint8List payload) {
    synchronized(_readQueue, () {
      _readQueue.add(payload);
      _readQueueCondition.broadcast();
    });
  }

  void sendReady() {
    _adbConnection.sendPacket(AdbProtocol.generateReady(_localId, _remoteId));
  }

  void updateRemoteId(int remoteId) => _remoteId = remoteId;

  void readyForWrite() {
    if (!_writeReady.isCompleted) {
      _writeReady.complete();
    } else {
      _writeReady = Completer<void>();
      _writeReady.complete();
    }
  }

  void notifyClose(bool closedByPeer) {
    if (closedByPeer && _readQueue.isNotEmpty) {
      _pendingClose = true;
    } else {
      _isClosed = true;
    }
    _streamCondition.broadcast();
    _readQueueCondition.broadcast();
  }

  Future<int> read(Uint8List bytes, int offset, int length) async {
    if (_readBufferPosition < _readBufferLimit) {
      return _readFromBuffer(bytes, offset, length);
    }

    return await synchronized(_readQueue, () async {
      Uint8List? data;
      while ((data = _readQueue.isEmpty ? null : _readQueue.removeFirst()) ==
              null &&
          !_isClosed) {
        await _readQueueCondition.wait();
      }

      if (data != null) {
        _readBufferPosition = 0;
        for (int i = 0; i < data.length; i++) {
          _readBuffer.setUint8(i, data[i]);
        }
        _readBufferLimit = data.length;
        if (_readBufferPosition < _readBufferLimit) {
          return _readFromBuffer(bytes, offset, length);
        }
      }

      if (_isClosed || (_pendingClose && _readQueue.isEmpty)) {
        throw IOException("流已关闭");
      }
      return -1;
    });
  }

  int _readFromBuffer(Uint8List bytes, int offset, int length) {
    int count = 0;
    for (int i = offset; i < offset + length; ++i) {
      if (_readBufferPosition < _readBufferLimit) {
        bytes[i] = _readBuffer.getUint8(_readBufferPosition++);
        ++count;
      }
    }
    return count;
  }

  Future<void> write(Uint8List bytes, int offset, int length) async {
    await synchronized(this, () async {
      while (!_isClosed && !_writeReady.isCompleted) {
        await _streamCondition.wait();
      }
      if (_isClosed) throw IOException("流已关闭");
      _writeReady = Completer<void>();
    });

    final maxPacketSize = _adbConnection.getMaxData();
    while (length > 0) {
      final chunkSize = length <= maxPacketSize ? length : maxPacketSize;
      await _adbConnection.sendPacket(
        AdbProtocol.generateWrite(
          _localId,
          _remoteId,
          bytes,
          offset,
          chunkSize,
        ),
      );
      offset += chunkSize;
      length -= chunkSize;
    }
  }

  Future<void> flush() async {
    if (_isClosed) throw IOException("流已关闭");
    await _adbConnection.flushPacket();
  }

  @override
  Future<void> close() async {
    await synchronized(this, () async {
      if (_isClosed) return;
      notifyClose(false);
    });
    await _adbConnection.sendPacket(
      AdbProtocol.generateClose(_localId, _remoteId),
    );
  }

  bool isClosed() => _isClosed;

  Future<int> available() async {
    return await synchronized(this, () async {
      if (_isClosed) throw IOException("流已关闭");
      if (_readBufferPosition < _readBufferLimit) {
        return _readBufferLimit - _readBufferPosition;
      }
      return _readQueue.firstOrNull?.length ?? 0;
    });
  }

  final _streamCondition = Condition();
  final _readQueueCondition = Condition();
}

Future<T> synchronized<T>(Object lock, Future<T> Function() critical) async {
  return await critical();
}

class Condition {
  final _completer = Completer<void>();
  bool _signaled = false;

  Future<void> wait() async {
    if (_signaled) {
      _signaled = false;
      return;
    }
    await _completer.future;
  }

  void broadcast() {
    _signaled = true;
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}

abstract class Closeable {
  Future<void> close();
}

// SPDX-License-Identifier: GPL-3.0-or-later OR Apache-2.0

/// libadb_dart库是libadb-android的Dart实现，用于通过ADB协议与Android设备通信。
library libadb_dart;

// 核心类导出
export 'src/adb_connection.dart';
export 'src/adb_stream.dart';
export 'src/adb_input_stream.dart';
export 'src/adb_output_stream.dart';
export 'src/abs_adb_connection_manager.dart';
export 'src/local_services.dart';

// 异常类导出
export 'src/exceptions/adb_authentication_failed_exception.dart';
export 'src/exceptions/adb_pairing_required_exception.dart';

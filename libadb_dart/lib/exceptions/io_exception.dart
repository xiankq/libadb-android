/// IO操作异常类
class IOException implements Exception {
  final String message;
  final Exception? cause;

  IOException([this.message = "", this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return "IOException: $message, Cause: $cause";
    }
    return "IOException: $message";
  }
}

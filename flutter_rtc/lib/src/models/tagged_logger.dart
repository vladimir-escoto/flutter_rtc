
import 'package:flutter/foundation.dart';

typedef Tag = String;
typedef MessageBuilder = String Function();

TaggedLogger taggedLogger({required Tag tag}) {
  return TaggedLogger(tag);
}

class TaggedLogger {
  const TaggedLogger(this.tag);

  final Tag tag;

  void v(MessageBuilder message) {
    debugPrint('$tag:${message()}');
  }

  void d(MessageBuilder message) {
    debugPrint('$tag:${message()}');
  }

  void i(MessageBuilder message) {
    debugPrint('$tag:${message()}');
  }

  void w(MessageBuilder message) {
    debugPrint('$tag:${message()}');
  }

  void e(MessageBuilder message) {
    debugPrint('$tag:${message()}');
  }

  void log(dynamic priority, MessageBuilder message) {
    debugPrint('$tag:${message()}');
  }
}
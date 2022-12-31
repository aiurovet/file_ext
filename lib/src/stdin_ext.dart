// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)
//

import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';

/// Event handler to read from stdin line-by-line (non-blocking)
///
typedef StdinLineHandler = Future<bool> Function(String);

/// Event handler to read from stdin line-by-line (blocking)
///
typedef StdinLineHandlerSync = bool Function(String);

/// Class for the formatted output
///
extension StdinExt on Stdin {
  /// Const: display name for stdin
  ///
  static const displayName = 'stdin';

  /// Const: name for stdin
  ///
  static const name = '-';

  /// Const: line separator
  ///
  static const newLine = '\n';

  /// Reads lines from [stdin] (non-blocking) and calls user event
  /// handler on each.\
  /// Returns the number of lines processed
  ///
  Future<int> forEachLine(
      {StdinLineHandler? handler, StdinLineHandlerSync? handlerSync}) async {
    var count = 0;
    var lines = getStreamQueue();

    while (await lines.hasNext) {
      var line = await lines.next;

      if ((handlerSync != null) && !handlerSync(line)) {
        break;
      }

      if ((handler != null) && !(await handler(line))) {
        break;
      }
    }

    return count;
  }

  /// Reads lines from [stdin] (blocking) and calls user event
  /// handler on each.\
  /// Returns the number of lines processed
  ///
  int forEachLineSync(StdinLineHandlerSync handler) {
    var count = 0;

    while (true) {
      final line = readLineSync();

      if ((line == null) || !handler(line)) {
        break;
      }
    }

    return count;
  }

  /// Reads the whole [stdin] (non-blocking) and returns
  /// that as a string buffer.\
  /// Returns the number of lines processed
  ///
  Future<String> readAsString() async {
    var result = '';
    var isFirst = true;
    var lines = getStreamQueue();

    while (await lines.hasNext) {
      if (isFirst) {
        isFirst = false;
      } else {
        result += newLine;
      }
      result += await lines.next;
    }

    return result;
  }

  /// Reads the whole [stdin] (non-blocking) and returns
  /// that as a string buffer.\
  /// Returns the number of lines processed
  ///
  String readAsStringSync() {
    var result = '';
    var isFirst = true;

    while (true) {
      final line = readLineSync();

      if (line == null) {
        break;
      }

      if (isFirst) {
        isFirst = false;
      } else {
        result += newLine;
      }

      result += line;
    }

    return result;
  }

  /// Returns stream queue based on [stdin]
  ///
  StreamQueue getStreamQueue() =>
      StreamQueue(LineSplitter().bind(Utf8Decoder().bind(this)));
}

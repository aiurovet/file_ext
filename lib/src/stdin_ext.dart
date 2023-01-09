// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)
//

import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';

/// Event handler to read from stdin line-by-line (non-blocking)
///
typedef StdinLineHandler = Future<bool> Function(String, int);

/// Event handler to read from stdin line-by-line (blocking)
///
typedef StdinLineHandlerSync = bool Function(String, int);

/// Class for the formatted output
///
extension StdinExt on Stdin {
  /// Const: display name for stdin
  ///
  static const displayName = 'stdin';

  /// Const: name for stdin
  ///
  static const name = '-';

  /// Const: line separator (POSIX-compliant)
  ///
  static const newLine = '\n';

  /// Const: line separator (MacOS-specific)
  ///
  static const newLineMac = '\r';

  /// Const: line separator (Windows-specific)
  ///
  static const newLineWin = '\r\n';

  /// Reads lines from [stdin] (non-blocking) and calls user event
  /// handler on each.\
  /// Returns the number of lines processed
  ///
  Future<int> forEachLine(
      {StdinLineHandler? handler, StdinLineHandlerSync? handlerSync}) async {
    var lineNo = 0;
    var lines = getStreamQueue();

    while (await lines.hasNext) {
      var line = await lines.next;
      ++lineNo;

      if ((handlerSync != null) && !handlerSync(line, lineNo)) {
        break;
      }

      if ((handler != null) && !(await handler(line, lineNo))) {
        break;
      }
    }

    return lineNo;
  }

  /// Reads lines from [stdin] (blocking) and calls user event
  /// handler on each.\
  /// Returns the number of lines processed
  ///
  int forEachLineSync(StdinLineHandlerSync handler) {
    var lineNo = 0;

    while (true) {
      ++lineNo;
      final line = readLineSync();

      if ((line == null) || !handler(line, lineNo)) {
        break;
      }
    }

    return lineNo;
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
      StreamQueue(LineSplitter().bind(utf8.decoder.bind(this)));
}

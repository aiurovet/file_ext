// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';

/// Model class for file name/path pattern with flags
///
class FilePattern {
  /// Exact match (true), case-insensitive (false) or OS-specific (null)
  ///
  final bool? caseSensitive;

  /// An opposite match
  ///
  final bool negative;

  /// Treat pattern as a regular expression pattern (true),
  /// glob pattern (false) or guess (null)
  ///
  late final bool regular;

  /// Actual pattern as string
  ///
  final String string;

  /// Pattern contains wide characters
  ///
  late final bool unicode;

  /// FilePattern for 'any file or path matches'
  ///
  static final FilePattern any =
      FilePattern(PathExt.anyPattern, caseSensitive: false, regular: false);

  /// Default constructor
  ///
  FilePattern(this.string,
      {this.caseSensitive, this.negative = false, this.regular = false}) {
    _setUnicodeFlag();
  }

  /// Default constructor
  ///
  void _setUnicodeFlag() {
    if (regular && string.contains(r'\p{')) {
      unicode = true;
      return;
    }

    final runes = string.runes;
    final length = runes.length;

    for (var i = 0;; i++) {
      if (i >= length) {
        unicode = false;
        return;
      }
      if (runes.elementAt(i) > 0xFFFF) {
        unicode = true;
        return;
      }
    }
  }
}

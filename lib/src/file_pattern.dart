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
  final bool inverse;

  /// Treat pattern as a regular expression pattern (true),
  /// glob pattern (false) or guess (null)
  ///
  late final bool regular;

  /// Actual pattern as string
  ///
  String string = '';

  /// Default constructor
  ///
  FilePattern(this.string,
      {this.caseSensitive, this.inverse = false, bool? regular}) {
    if (regular == null) {
      this.regular = PathExt.isRegExpPattern(string);
    } else {
      this.regular = regular;
    }
  }

  /// FilePattern for 'any file or path matches'
  ///
  static final FilePattern any =
      FilePattern(PathExt.anyPattern, caseSensitive: false, regular: false);
}

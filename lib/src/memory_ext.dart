// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/memory.dart';

/// A callback function defintion
///
typedef MemoryFileSystemHandler = void Function(MemoryFileSystem fs);

/// A helper extension for the MemoryFileSystem API
/// Useful mostly for unit tests
///
extension MemoryFileSystemExt on MemoryFileSystem {
  /// Get memory file systems of all styles
  ///
  static List<MemoryFileSystem> get all => _all;
  static final _all = [
    MemoryFileSystem(style: FileSystemStyle.posix),
    MemoryFileSystem(style: FileSystemStyle.windows),
  ];

  /// Private: regular expression to get name
  ///
  static final _styleNameRE = RegExp('^.*_([^\'"]+).*');

  /// The way to perform processing for each in-memory file system
  ///
  static void forEach(MemoryFileSystemHandler handler) {
    for (final mfs in _all) {
      handler(mfs);
    }
  }

  /// Get human-readable name
  ///
  String getStyleName() => style
      .toString()
      .replaceAllMapped(_styleNameRE, (m) => m.group(1)!.toLowerCase());
}

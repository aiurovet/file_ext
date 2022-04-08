// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/memory.dart';

/// A helper extension for the MemoryFileSystem API
/// Useful mostly for unit tests
///
extension MemoryFileSystemExt on MemoryFileSystem {
  static final _memoryFileSystems = [
    MemoryFileSystem(style: FileSystemStyle.posix),
    MemoryFileSystem(style: FileSystemStyle.windows)
  ];

  /// The way to perform processing for each in-memory file system
  ///
  static void forEach(void Function(MemoryFileSystem fs) handler) {
    for (var fs in _memoryFileSystems) {
      handler(fs);
    }
  }

  /// Short name
  ///
  String get styleName =>
      (style == FileSystemStyle.posix ? 'POSIX' : 'Windows');
}

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

  /// The way to perform processing for each in-memory file system
  ///
  static void forEach(MemoryFileSystemHandler handler) {
    for (final mfs in _all) {
      handler(mfs);
    }
  }

  /// Get short style name
  ///
  String getStyleName() {
    final name = style.toString();
    final start = name.lastIndexOf('_');
    var end = name.length;
    final lastCode = name[end - 1].toLowerCase().codeUnitAt(0);

    if ((lastCode < 0x60 /* 'a' */) || (lastCode > 0x7A /* 'z' */)) {
      --end;
    }

    return name.substring(start + 1, end);
  }
}

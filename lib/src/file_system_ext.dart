// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';

/// A helper extension for the FileSystem API
///
extension FileSystemExt on FileSystem {
  /// A wrapper for `FileList(...).exec(...)`, asynchronous (non-blocking)
  ///
  Future<List<String>> list(
      {String? root,
      List<String>? roots,
      String? pattern,
      List<String>? patterns,
      bool accumulate = true,
      bool allowHidden = false,
      FileSystemEntityType? type,
      List<FileSystemEntityType>? types,
      FileFilterProc? filterProc,
      FileFilterProcSync? filterProcSync,
      FileFilterErrorProc? errorProc,
      bool followLinks = true}) async =>
    await FileList(this,
        root: root,
        roots: roots,
        pattern: pattern,
        patterns: patterns,
        type: type,
        types: types,
        accumulate: accumulate,
        allowHidden: allowHidden,
        filterProc: filterProc,
        filterProcSync: filterProcSync,
        followLinks: followLinks)
        .exec();

  /// A wrapper for `FileList(...).execSync(...)`, synchronous (blocking)
  ///
  Future<List<String>> listSync(
      {String? root,
      List<String>? roots,
      String? pattern,
      List<String>? patterns,
      bool accumulate = true,
      bool allowHidden = false,
      FileSystemEntityType? type,
      List<FileSystemEntityType>? types,
      FileFilterProc? filterProc,
      FileFilterProcSync? filterProcSync,
      FileFilterErrorProc? errorProc,
      bool followLinks = true}) async =>
    FileList(this,
        root: root,
        roots: roots,
        pattern: pattern,
        patterns: patterns,
        type: type,
        types: types,
        accumulate: accumulate,
        allowHidden: allowHidden,
        filterProc: filterProc,
        filterProcSync: filterProcSync,
        followLinks: followLinks)
        .execSync();
}

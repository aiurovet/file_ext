// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';

/// A helper extension for the FileSystem API
///
extension FileSystemExt on FileSystem {
  /// Convert [aPath] to the fully qualified path\
  /// \
  /// For POSIX, it calls `canonicalize()`\
  /// For Windows, it takes an absolute path,
  /// prepends it with the current drive (if omitted),
  /// and resolves . and ..
  ///
  String getFullPath(String? aPath) {
    // If path is null, return the current directory
    //
    if (aPath == null) {
      return path.current;
    }

    // If path is empty, return the current directory
    //
    if (aPath.isEmpty) {
      return path.current;
    }

    // Posix is always 'in chocolate'
    //
    if (path.isPosix) {
      return path.canonicalize(aPath);
    }

    // Get absolute path
    //
    final separator = path.separator;
    var absPath = file(path.adjust(aPath)).absolute.path;

    // If no drive is present, then take it from the current directory
    //
    if (absPath.startsWith(separator)) {
      final curDirName = path.current;
      absPath =
          curDirName.substring(0, curDirName.indexOf(separator)) + absPath;
    }

    // Split path in parts (drive, directories, basename)
    //
    final parts = absPath.split(separator);
    var drive = parts[0];

    // Resolve all . and .. occurrences
    //
    var result = '';

    for (var i = 0, n = parts.length; i < n; i++) {
      final part = parts[i];

      switch (part) {
        case '':
          continue;
        case PathExt.shortCurDirName:
          continue;
        case PathExt.shortParentDirName:
          final breakPos = result.lastIndexOf(separator);
          if (breakPos >= 0) {
            result = result.substring(0, breakPos);
          }
          continue;
        default:
          if (i > 0) {
            // full path should start with drive
            result += separator;
          }
          result += part;
          continue;
      }
    }

    // Disaster recovery
    //
    if (result.isEmpty) {
      result = drive + separator;
    } else if (result == drive) {
      result += separator;
    }

    // Return the result
    //
    return result;
  }

  /// A wrapper for `FileList(...).exec(...)`, asynchronous (non-blocking)
  ///
  Future<List<String>> list(
          {String? root,
          List<String>? roots,
          FilePattern? pattern,
          List<FilePattern>? patterns,
          FileSystemEntityType? type,
          List<FileSystemEntityType>? types,
          bool accumulate = true,
          bool allowHidden = false,
          bool followLinks = true,
          FileListProc? listProc,
          FileListProcSync? listProcSync,
          FileListErrorProc? errorProc}) async =>
      await FileList(this,
              root: root,
              roots: roots,
              pattern: pattern,
              patterns: patterns,
              type: type,
              types: types,
              accumulate: accumulate,
              allowHidden: allowHidden,
              followLinks: followLinks,
              listProc: listProc,
              listProcSync: listProcSync,
              errorProc: errorProc)
          .fetch();

  /// A wrapper for `FileList(...).execSync(...)`, synchronous (blocking)
  ///
  List<String> listSync(
          {String? root,
          List<String>? roots,
          FilePattern? pattern,
          List<FilePattern>? patterns,
          FileSystemEntityType? type,
          List<FileSystemEntityType>? types,
          bool accumulate = true,
          bool allowHidden = false,
          bool followLinks = true,
          FileListProcSync? listProcSync,
          FileListErrorProc? errorProc}) =>
      FileList(this,
              root: root,
              roots: roots,
              pattern: pattern,
              patterns: patterns,
              type: type,
              types: types,
              accumulate: accumulate,
              allowHidden: allowHidden,
              followLinks: followLinks,
              listProcSync: listProcSync,
              errorProc: errorProc)
          .fetchSync();
}

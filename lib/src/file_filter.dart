// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';
import 'package:glob/glob.dart';

/// Model class for file name/path pattern with flags
///
class FileFilter {
  /// FileSystem object
  ///
  final FileSystem fileSystem;

  /// Exact match (true), case-insensitive (false) or OS-specific (null)
  ///
  late final bool isCaseSensitive;

  /// An opposite match
  ///
  final bool isNegative;

  /// Match file system entity path rather than basename against the pattern
  ///
  late final bool isMatchPath;

  /// Sub-directories scan required
  ///
  late final bool isRecursive;

  /// Treat pattern as a regular expression pattern (true),
  /// glob pattern (false) or guess (null)
  ///
  late final bool isRegular;

  /// Actual pattern as string
  ///
  late final String pattern;

  /// Internal: actual glob pattern
  ///
  late final Glob? glob;

  /// Internal: actual regular expression
  ///
  late final RegExp? regExp;

  /// Default constructor
  ///
  FileFilter(this.fileSystem, String pattern,
      {bool? isCaseSensitive,
      this.isNegative = false,
      this.isRegular = false}) {
    final fsp = fileSystem.path;
    final isPosix = fsp.isPosix;

    if (pattern.trim().isEmpty) {
      pattern = PathExt.anyPattern(false);
    }

    if (isPosix) {
      this.pattern = pattern;
    } else if (isRegular) {
      this.pattern = fsp.toPosixEscaped(pattern);
    } else {
      this.pattern = fsp.toPosix(pattern);
    }

    this.isCaseSensitive = isCaseSensitive ?? isPosix;

    if (isRegular) {
      isRecursive =
          pattern.replaceAll(r'\\', '').replaceAll(r'\.', '').contains('.*');
    } else {
      isRecursive = pattern.contains('**');
    }

    isMatchPath =
        isRecursive || this.pattern.contains(PathExt.pathSeparatorPosix);

    if (isRegular) {
      glob = null;
      regExp = RegExp(pattern, caseSensitive: this.isCaseSensitive, unicode: true);
    } else {
      glob = Glob(pattern,
          context: fileSystem.path, caseSensitive: this.isCaseSensitive);
      regExp = null;
    }
  }

  /// FilePattern for 'any file or path matches'
  ///
  static FileFilter any(FileSystem fileSystem, {bool isRecursive = false}) =>
      FileFilter(fileSystem, PathExt.anyPattern(isRecursive));

  /// If pattern represents a directory, then re-create new filter by appending 'anyPattern'
  ///
  Future<FileFilter> adjust(FileSystem fileSystem) async {
    if (isRegular || !(await fileSystem.directory(pattern).exists())) {
      return this;
    }
    return copyWith(
        pattern:
            fileSystem.path.join(pattern, PathExt.anyPattern(isRecursive)));
  }

  /// If pattern represents a directory, then re-create new filter by appending 'anyPattern' (sync)
  ///
  FileFilter adjustSync(FileSystem fileSystem) {
    if (isRegular || !(fileSystem.directory(pattern).existsSync())) {
      return this;
    }
    return copyWith(
        pattern:
            fileSystem.path.join(pattern, PathExt.anyPattern(isRecursive)));
  }

  /// FilePattern for 'any file or path matches'
  ///
  FileFilter copyWith(
          {FileSystem? fileSystem,
          String? pattern,
          bool? isCaseSensitive,
          bool? isNegative,
          bool? isRegular}) =>
      FileFilter(fileSystem ?? this.fileSystem, pattern ?? this.pattern,
          isCaseSensitive: isCaseSensitive ?? this.isCaseSensitive,
          isNegative: isNegative ?? this.isNegative,
          isRegular: isRegular ?? this.isRegular);

  /// Actual filtering
  ///
  bool hasMatch(String posixPath, String baseName) {
    final input = (isMatchPath ? posixPath : baseName);
    final hasMatch = glob?.matches(input) ?? regExp?.hasMatch(input) ?? false;

    return hasMatch ^ isNegative;
  }
}

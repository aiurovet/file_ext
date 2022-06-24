// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// A supplementary class for `list(...)` and `listSync(...)` of `FileSystemExt`
///
class FileFilter {
  /// Filter matching any filename or path
  ///
  static FileFilter any(FileSystem fileSystem) =>
      FileFilter(fileSystem)..setPattern(FilePattern.any);

  /// The filesystem object
  ///
  late final FileSystem fileSystem;

  /// The context object
  ///
  late final p.Context path;

  /// The glob object
  ///
  Glob? get glob => _glob;
  Glob? _glob;

  /// A flag indicating the filtering must apply to the whole
  /// paths rather than basenames
  ///
  bool get matchWholePath => _matchWholePath;
  var _matchWholePath = false;

  /// A flag indicating the pattern is meant for checking
  /// a string does not match the glob
  ///
  bool get negative => _negative;
  var _negative = false;

  /// The original pattern
  ///
  String get pattern => _pattern;
  var _pattern = '';

  /// The regular expression object
  ///
  RegExp? get regExp => _regExp;
  RegExp? _regExp;

  /// The top directory to start from (for glob patterns only)
  ///
  String dirName = '';

  /// The constructor
  ///
  FileFilter(FileSystem? fileSystem) {
    this.fileSystem = fileSystem ?? FileSystemExt.local;
    path = this.fileSystem.path;
  }

  /// Get the actual glob object for the filesystem entities filtering,
  /// at this point, the pattern is guaranteed to be without the negation
  /// prefix
  ///
  void _createGlob(FilePattern pattern, bool isDirectory) {
    if (isDirectory) {
      dirName = _pattern;
      _pattern = PathExt.anyPattern;
      _matchWholePath = false;
    } else {
      final parts = path.splitPattern(_pattern);
      dirName = parts[0];
      _pattern = parts[1];
      _matchWholePath = _pattern.contains(path.separator);
    }

    _regExp = null;
    _glob = Glob(_pattern,
        context: path,
        recursive: path.isRecursivePattern(_pattern),
        caseSensitive: pattern.caseSensitive ?? path.isPosix);
  }

  /// Get the actual regexp object for the filesystem entities filtering
  ///
  void _createRegExp(FilePattern pattern) {
    _pattern = path.adjustEscaped(_pattern);
    _matchWholePath = _pattern.contains(path.separatorEscaped);
    _glob = null;
    _regExp = RegExp(_pattern,
        caseSensitive: pattern.caseSensitive ?? path.isPosix,
        unicode: pattern.unicode);
  }

  /// Check the [path] matches the straight pattern (without the leading negation
  /// characters) and return the opposite if [_negative] match is required
  ///
  bool matches(String path, String baseName) {
    var text = (_matchWholePath ? path : baseName);
    return (_glob?.matches(text) ?? _regExp?.hasMatch(text) ?? true) ^
        _negative;
  }

  /// The method to set pattern (async)
  ///
  void _setPattern(FilePattern pattern, bool isDirectory) {
    _negative = pattern.negative;
    _pattern = path.adjust(pattern.string);

    if (pattern.regular && !isDirectory) {
      _createRegExp(pattern);
    } else {
      _createGlob(pattern, isDirectory);
    }
  }

  /// The method to set pattern (async)
  ///
  Future setPattern(FilePattern pattern) async {
    final pat = pattern.string;

    // Windows-style MemoryFileSystem breaks if path is less than 3 characters
    //
    var isDir = ((pat == path.separator) || (pat == PathExt.altSeparator));

    if (!isDir) {
      isDir = await fileSystem.isDirectory(pat);
    }

    _setPattern(pattern, isDir);
  }

  /// The method to set pattern (async)
  ///
  void setPatternSync(FilePattern pattern) {
    final pat = pattern.string;

    // Windows-style MemoryFileSystem breaks if path is less than 3 characters
    //
    var isDir = ((pat == path.separator) || (pat == PathExt.altSeparator));

    if (!isDir) {
      isDir = fileSystem.isDirectorySync(pat);
    }

    _setPattern(pattern, isDir);
  }
}

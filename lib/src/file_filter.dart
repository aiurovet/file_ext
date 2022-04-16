// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_ext/file_ext.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// A supplementary class for `list(...)` and `listSync(...)` of `FileSystemExt`
///
class FileFilter {
  /// A regexp to discover negation like: `~*.obj``\
  /// Requires the actual pattern not to start with -\
  /// All white spaces (spaces, tabs, new line characters)
  /// surrounding the negation are removed, multiple
  /// negations are treated as a single one
  ///
  static final RegExp negationRE = RegExp(r'^\s*<>+\s*');

  /// The filesystem object
  ///
  late final FileSystem fileSystem;

  /// The context object
  ///
  late final p.Context path;

  /// The glob object
  ///
  late final Glob? glob;

  /// A flag indicating the filtering must apply to the whole
  /// paths rather than basenames
  ///
  late final bool matchPath;

  /// A flag indicating the pattern is meant for checking
  /// a string does not match the glob
  ///
  late final bool negative;

  /// The original pattern
  ///
  String pattern = '';

  /// The regular expression object
  ///
  late final RegExp? regexp;

  /// The top directory to start from (for glob patterns only)
  /// Should never be an empty string
  ///
  String root = '';

  /// The constructor
  ///
  FileFilter(FileSystem? fileSystem) {
    this.fileSystem = fileSystem ?? LocalFileSystem();
    path = this.fileSystem.path;
  }

  /// The method to set pattern (async)
  ///
  Future setPattern(String pattern,
      {bool allowCompoundPatterns = true,
      bool? caseSensitive,
      bool? negative}) async {
    _getPatternAndNegative(pattern, allowCompoundPatterns, negative);
    _setPattern(allowCompoundPatterns, caseSensitive, negative,
        await fileSystem.isDirectory(this.pattern));
  }

  /// The method to set pattern (async)
  ///
  void setPatternSync(String pattern,
      {bool allowCompoundPatterns = true,
      bool? caseSensitive,
      bool? negative}) {
    _getPatternAndNegative(pattern, allowCompoundPatterns, negative);
    _setPattern(allowCompoundPatterns, caseSensitive, negative,
        fileSystem.isDirectorySync(this.pattern));
  }

  /// Check the [path] matches the straight pattern (without the leading negation
  /// characters) and return the opposite if [negative] match is required
  ///
  bool matches(String path, String baseName) {
    var text = (matchPath ? path : baseName);
    return (glob?.matches(text) ?? regexp?.hasMatch(text) ?? true) ^ negative;
  }

  /// The serializer
  ///
  @override
  String toString() => pattern;

  /// Get the actual glob object for the filesystem entities filtering,
  /// at this point, the pattern is guaranteed to be without the negation
  /// prefix
  ///
  void _createGlobObject(
      bool allowCompoundPatterns, bool? caseSensitive, bool? negative) {
    final parts = path.splitPattern(pattern);
    root = parts[0];
    pattern = parts[1];
    matchPath = pattern.contains(path.separator);

    regexp = null;
    glob = Glob(pattern,
        context: path,
        recursive: PathExt.isRecursiveGlobPattern(parts[1]),
        caseSensitive: caseSensitive);
  }

  /// Get the actual regexp object for the filesystem entities filtering
  ///
  void _createRegExpObject(
      bool allowCompoundPatterns, bool? caseSensitive, bool? negative) {
    pattern = path.adjustEscaped(pattern);
    matchPath = pattern.contains(path.separatorEscaped);
    glob = null;
    regexp = RegExp(pattern, caseSensitive: caseSensitive ?? false);
  }

  /// Remove all leading negation chars from [pattern] and set [negative] flag
  ///
  void _getPatternAndNegative(
      String pattern, bool allowCompoundPatterns, bool? negative) {
    if (allowCompoundPatterns && (negative == null)) {
      var match = negationRE.firstMatch(pattern);

      if ((match != null) && (match.start == 0)) {
        this.negative = true;
        this.pattern = pattern.substring(match.end);
      }
    }

    this.negative = false;
    this.pattern = pattern;
  }

  /// The method to set pattern (async)
  ///
  void _setPattern(bool allowCompoundPatterns, bool? caseSensitive,
      bool? negative, bool isDirectory) {
    if (PathExt.isRegExpPattern(pattern)) {
      _createRegExpObject(allowCompoundPatterns, caseSensitive, negative);
    } else {
      _createGlobObject(allowCompoundPatterns, caseSensitive, negative);
    }
  }
}

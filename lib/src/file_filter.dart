// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// A supplementary class for `list(...)` and `listSync(...)` of `FileSystemExt`
///
class FileFilter {
  /// A regexp to discover negation like: `-*.obj``\
  /// Requires the actual pattern not to start with -\
  /// All white spaces (spaces, tabs, new line characters)
  /// surrounding the negation are removed, multiple
  /// negations are treated as a single one
  ///
  static final RegExp negationRE = RegExp(r'^\s*-+\s*');

  /// The context object
  ///
  late final p.Context context;

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
  FileFilter(this.pattern,
      {p.Context? context,
      bool allowCompoundPatterns = true,
      bool? caseSensitive,
      bool? negative}) {
    this.context = context ?? p.Context();
    var straight =
        _getStraightPattern(pattern, allowCompoundPatterns, negative);

    if (PathExt.isRegExpPattern(straight)) {
      _createRegExpObject(
          straight, allowCompoundPatterns, caseSensitive, negative);
    } else {
      _createGlobObject(
          straight, allowCompoundPatterns, caseSensitive, negative);
    }
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

  /// Get the actual glob object for the filesystem entities filtering
  /// [straightPattern] is guaranteed not to have negation prefix
  ///
  void _createGlobObject(String straightPattern, bool allowCompoundPatterns,
      bool? caseSensitive, bool? negative) {
    final parts = context.splitPattern(straightPattern);
    root = parts[0];
    pattern = parts[1];
    matchPath = pattern.contains(context.separator);

    regexp = null;
    glob = Glob(pattern,
        context: context,
        recursive: PathExt.isRecursiveGlobPattern(parts[1]),
        caseSensitive: caseSensitive);
  }

  /// Get the actual regexp object for the filesystem entities filtering
  ///
  void _createRegExpObject(String pattern, bool allowCompoundPatterns,
      bool? caseSensitive, bool? negative) {
    pattern = context.adjustEscaped(pattern);
    matchPath = pattern.contains(context.separatorEscaped);
    glob = null;
    regexp = RegExp(pattern, caseSensitive: caseSensitive ?? false);
  }

  /// Remove all leading negation chars from [pattern] and set [negative] flag
  ///
  String _getStraightPattern(
      String pattern, bool allowCompoundPatterns, bool? negative) {
    if (allowCompoundPatterns && (negative == null)) {
      var match = negationRE.firstMatch(pattern);

      if ((match != null) && (match.start == 0)) {
        this.negative = true;
        return pattern.substring(match.end);
      }
    }

    this.negative = false;
    return pattern;
  }
}

// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// A supplementary class for `list(...)` and `listSync(...)` of `FileSystemExt`
///
class FileFilter {
  /// A regexp to discover negation
  ///
  static final RegExp negationRE = RegExp(r'^\s*~\s+');

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
  ///
  String root = '';

  /// The constructor
  ///
  FileFilter(this.pattern,
      {p.Context? context, bool? caseSensitive, bool? negative}) {
    this.context = context ?? p.Context();
    var straight = _getStraightPattern(pattern, negative);

    if (PathExt.isRegExpPattern(straight)) {
      _createRegExpObject(straight, caseSensitive, negative);
    } else {
      _createGlobObject(straight, caseSensitive, negative);
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
  ///
  void _createGlobObject(
      String straightPattern, bool? caseSensitive, bool? negative) {
    var parts = context.splitPattern(straightPattern);
    var root = parts[0];
    pattern = parts[1];
    matchPath = root.isNotEmpty || straightPattern.contains(context.separator);
    this.root = root.isEmpty ? '.' : root;
    glob = Glob(straightPattern,
        context: context,
        recursive: PathExt.isRecursiveGlobPattern(parts[1]),
        caseSensitive: caseSensitive);
    regexp = null;
  }

  /// Get the actual regexp object for the filesystem entities filtering
  ///
  void _createRegExpObject(
      String pattern, bool? caseSensitive, bool? negative) {
    pattern = context.adjustEscaped(pattern);
    matchPath = pattern.contains(context.separatorEscaped);
    regexp = RegExp(pattern, caseSensitive: caseSensitive ?? false);
    glob = null;
  }

  /// Remove all leading negation chars from [pattern] and set [negative] flag
  ///
  String _getStraightPattern(String pattern, bool? negative) {
    if (negative == null) {
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

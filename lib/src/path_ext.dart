// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// A helper extension for the Path API
///
extension PathExt on p.Context {
  /// Alt directory separator (differs from separator for Windows-style FS only)
  ///
  static const altSeparator = r'/';

  /// A variant of [altSeparator] for regexp patterns
  ///
  static const altSeparatorEscaped = r'\\';

  /// A pattern to list any file system element
  ///
  static final anyPattern = r'*';

  /// A variant of [anyPattern] to perform recursive scans
  ///
  static final anyPatternRecursive = r'**';

  /// A separator between the drive name and the rest of the path
  /// (relevant to Windows only)
  ///
  static final driveSeparator = r':';

  /// A variant of [driveSeparator] for regexp patterns
  ///
  static final driveSeparatorEscaped = r':';

  /// Check whether the file system is case-sensitive
  ///
  bool get isCaseSensitive => (separator == altSeparator);

  /// A pattern to locate glob patterns
  ///
  static final isGlobPatternRE = RegExp(r'[\*\?\{\[]', caseSensitive: false);

  /// A regexp to filter hidden files
  ///
  static final RegExp isHiddenRE = RegExp(r'(^|[\/\\])\.[^\.\/\\]');

  /// A pattern to locate a combination of glob characters which means recursive directory scan
  ///
  static final isRecursiveGlobPatternRE =
      RegExp(r'\*\*|[\*\?].*[\/\\]', caseSensitive: false);

  /// A pattern to locate regular expression patterns
  ///
  static final isRegExpPatternRE =
      RegExp(r'^\^|\$$|[\|\(]', caseSensitive: false);

  /// Check whether the file system is POSIX-compliant
  ///
  bool get isPosix => (separator == altSeparator);

  /// A variant of [separator] for regexp patterns
  ///
  String get separatorEscaped => r'\' + separator;

  /// A short name of the current directory
  ///
  static const String shortCurDirName = '.';

  /// A short name of the parent directory
  ///
  static const String shortParentDirName = '..';

  /// Adjust [aPath] by replacing every alt separator with the core one
  /// (the opposite to `toPosix(...)`)
  ///
  String adjust(String? aPath) {
    if (aPath == null) {
      return '';
    }
    if (aPath.isEmpty || (separator == altSeparator)) {
      return aPath;
    }
    return aPath.replaceAll(altSeparator, separator);
  }

  /// A variant of `adjust(...)` for regexp patterns
  ///
  String adjustEscaped(String? aPath) {
    if ((aPath == null) || aPath.isEmpty) {
      return '';
    }
    if (isPosix) {
      return aPath;
    }
    return aPath.replaceAll(altSeparatorEscaped, separatorEscaped);
  }

  String adjustTrailingSeparator(String? aPath, FileSystemEntityType type,
      {bool append = false}) {
    if ((aPath == null) || aPath.isEmpty) {
      return '';
    }

    final lastPos = aPath.length - 1;

    if (aPath[lastPos] == separator) {
      if (!isPosix) {
        if ((lastPos >= 1) && (aPath[lastPos - 1] == driveSeparator)) {
          return aPath;
        }
      }
      return (append ? aPath : aPath.substring(0, lastPos - 1));
    }

    return (append ? aPath + separator : aPath);
  }

  /// Convert [pattern] string to a proper glob object
  ///
  Glob createGlob(String? pattern) {
    var patternEx =
        ((pattern == null) || pattern.isEmpty ? anyPattern : pattern);

    return Glob(patternEx,
        context: this,
        recursive: isRecursiveGlobPattern(patternEx),
        caseSensitive: isCaseSensitive);
  }

  /// Check whether [pattern] contains spoecial glob pattern characters
  ///
  static bool isGlobPattern(String? pattern) =>
      (pattern != null) && isGlobPatternRE.hasMatch(pattern);

  /// Check whether [aPath] represents a hidden file or directory:
  /// i.e. [aPath] contains a sub-dir or a filename starting with
  /// a dot
  ///
  bool isHidden(String aPath) => isHiddenRE.hasMatch(aPath);

  /// Return true if [aPath] contains a separator
  /// Under Windows, return true also if [aPath] contains
  /// altSeparator or driveSeparator
  ///
  bool isPath(String? aPath) {
    if ((aPath == null) || aPath.isEmpty) {
      return false;
    }
    if (aPath.contains(separator)) {
      return true;
    }
    if (separator == altSeparator) {
      return false;
    }
    return (aPath.contains(altSeparator) || aPath.contains(driveSeparator));
  }

  /// A variant of `isPath(...)` for regexp patterns
  ///
  bool isPathEscaped(String? aPath) {
    if ((aPath == null) || aPath.isEmpty) {
      return false;
    }
    if (aPath.contains(separatorEscaped)) {
      return true;
    }
    if (separator == altSeparatorEscaped) {
      return false;
    }
    return (aPath.contains(altSeparatorEscaped) ||
        aPath.contains(driveSeparatorEscaped));
  }

  /// Check whether [pattern] indicates recursive directory scan
  ///
  static bool isRecursiveGlobPattern(String? pattern) =>
      (pattern != null) && isRecursiveGlobPatternRE.hasMatch(pattern);

  /// Check whether [pattern] contains spoecial glob pattern characters
  ///
  static bool isRegExpPattern(String? pattern) =>
      (pattern != null) && isRegExpPatternRE.hasMatch(pattern);

  /// Adjust [pattern] if needed, then split that into a non-glob root directory name and a glob sub-pattern:\
  /// `'/ab.ijk' => '/', 'ab.ijk'` (POSIX)\
  /// `'C:\ab.ijk' => 'C:\', 'ab.ijk'` (Windows)\
  /// `'/ab/cd/efgh.ijk' => '/ab/cd', 'efgh.ijk'` (POSIX)\
  /// `'/ab/cd/efgh.ijk' => '\ab\cd', 'efgh.ijk'` (Windows)\
  /// `'ab\cd*/efgh/**.ijk' => '', 'ab\cd*/efgh/**.ijk'` (POSIX)\
  /// `'ab\cd\*/efgh\**.ijk' => 'ab', 'cd\*\efgh\**.ijk' (Windows)`
  ///
  List<String> splitPattern(String? pattern, {bool isAdjusted = false}) {
    if ((pattern == null) || pattern.isEmpty) {
      return ['', anyPattern];
    }

    var patternEx = isAdjusted ? pattern : adjust(pattern);

    if (!patternEx.contains(separator)) {
      return ['', patternEx];
    }

    var globPos = isGlobPatternRE.firstMatch(patternEx)?.start ?? -1;
    var subPattern =
        (globPos < 0 ? patternEx : patternEx.substring(0, globPos));
    var lastSepPos = subPattern.lastIndexOf(separator);

    if (lastSepPos < 0) {
      return ['', patternEx];
    }

    subPattern = patternEx.substring(lastSepPos + 1);

    if ((lastSepPos == 0) ||
        (!isPosix && (patternEx[lastSepPos - 1] == driveSeparator))) {
      ++lastSepPos;
    }

    var root = patternEx.substring(0, lastSepPos);

    if (subPattern.isEmpty) {
      subPattern = anyPattern;
    }

    return [root, subPattern];
  }

  /// Convert all separators in [aPath] to the POSIX-compliant ones
  /// (the opposite to `adjust(...)`)
  ///
  String toPosix(String? aPath) {
    if (aPath == null) {
      return '';
    }
    if (aPath.isEmpty || (separator == altSeparator)) {
      return aPath;
    }
    return aPath.replaceAll(separator, altSeparator);
  }

  /// A variant of `toPosix(...)` for regexp patterns
  ///
  String toPosixEscaped(String? aPath) {
    if (aPath == null) {
      return '';
    }
    if (aPath.isEmpty || (separator == altSeparator)) {
      return aPath;
    }
    return aPath.replaceAll(separatorEscaped, altSeparatorEscaped);
  }
}

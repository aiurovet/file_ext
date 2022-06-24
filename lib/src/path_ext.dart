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
  static final altSeparatorEscaped = RegExp.escape(altSeparator);

  /// A pattern to list any file system element
  ///
  static final anyPattern = r'*';

  /// A variant of [anyPattern] to perform recursive scans
  ///
  static final anyPatternRecursive = '$anyPattern$anyPattern';

  /// Check whether the file system is case-sensitive
  ///
  bool get caseSensitive => (separator == altSeparator);

  /// A separator between the drive name and the rest of the path
  /// (relevant to Windows only)
  ///
  static final driveSeparator = r':';

  /// A variant of [driveSeparator] for regexp patterns
  ///
  static final driveSeparatorEscaped = r':';

  /// A pattern to locate glob patterns
  ///
  static final _globPatternRE = RegExp(r'[!\*\?\{\[]', caseSensitive: false);

  /// A regexp to filter hidden files (POSIX)
  ///
  static final RegExp _hiddenPosixRE = RegExp(r'^\.+([^\.\/]|$)|\/\.+[^\.\/]');

  /// A regexp to filter hidden files (Windows)
  ///
  static final RegExp _hiddenWindowsRE =
      RegExp(r'^\.+([^\.\/\\]|$)|[\/\\]\.+[^\.\/\\]');

  /// Check whether the file system is POSIX-compliant
  ///
  bool get isPosix => (separator == altSeparator);

  /// A variant of [separator] for regexp patterns
  ///
  String get separatorEscaped => RegExp.escape(separator);

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
    if (type != FileSystemEntityType.directory) {
      return aPath;
    }

    final lastPos = aPath.length - 1;
    final lastChr = aPath[lastPos];

    if (lastChr == separator) {
      if (!isPosix) {
        if ((lastPos >= 1) && (aPath[lastPos - 1] == driveSeparator)) {
          return aPath;
        }
      }
      return (append ? aPath : aPath.substring(0, lastPos));
    } else if ((lastChr == driveSeparator) && append && !isPosix) {
      return aPath + shortCurDirName + separator;
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
        recursive: isRecursivePattern(patternEx),
        caseSensitive: caseSensitive);
  }

  /// Check whether [pattern] contains spoecial glob pattern characters
  ///
  static bool isGlobPattern(String? pattern) =>
      (pattern != null) && _globPatternRE.hasMatch(pattern);

  /// Check whether [aPath] represents a hidden file or directory:
  /// i.e. [aPath] contains a sub-dir or a filename starting with
  /// a dot (on either POSIX or Windows)
  ///
  bool isHidden(String aPath) => (isPosix
      ? _hiddenPosixRE.hasMatch(aPath)
      : _hiddenWindowsRE.hasMatch(aPath));

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
  bool isRecursivePattern(String? pattern) =>
      (pattern != null) && pattern.contains(anyPatternRecursive);

  /// Adjust [pattern] if needed, then split that into a non-glob root directory name and a glob sub-pattern:\
  /// `'/ab.ijk' => '/', 'ab.ijk'` (POSIX)\
  /// `'C:\ab.ijk' => 'C:\', 'ab.ijk'` (Windows)\
  /// `'/ab/cd/efgh.ijk' => '/ab/cd', 'efgh.ijk'` (POSIX)\
  /// `'/ab/cd/efgh.ijk' => '\ab\cd', 'efgh.ijk'` (Windows)\
  /// `'ab\cd*/efgh/**.ijk' => '', 'ab\cd*/efgh/**.ijk'` (POSIX)\
  /// `'ab\cd\*/efgh\**.ijk' => 'ab', 'cd\*\efgh\**.ijk' (Windows)`
  ///
  List<String> splitPattern(String? pattern, {bool adjusted = false}) {
    if ((pattern == null) || pattern.isEmpty) {
      return ['', anyPattern];
    }

    var patternEx = adjusted ? pattern : adjust(pattern);

    if (!patternEx.contains(separator)) {
      return ['', patternEx];
    }

    var globPos = _globPatternRE.firstMatch(patternEx)?.start ?? -1;
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

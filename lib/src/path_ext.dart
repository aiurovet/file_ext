// Copyright (c) 2022-2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// A helper extension for Path API
///
extension PathExt on p.Context {
  /// A pattern to list any file system element (non-recursive)
  ///
  static const anyPattern = '*';

  /// A pattern to list any file system element (recursive)
  ///
  static const anyPatternRecursive = '**';

  /// Alt directory separator (differs from separator for Windows-style FS only)
  ///
  static const altSeparator = separatorPosix;

  /// Const: path separator for POSIX-like filesystems
  ///
  static const separatorPosix = r'/';

  /// Const: path separator for Windows filesystem
  ///
  static const separatorWindows = r'\';

  /// A separator between the drive name and the rest of the path
  /// (relevant to Windows only)
  ///
  static final driveSeparator = r':';

  /// A regexp to filter hidden files (POSIX)
  ///
  static final RegExp _hiddenPosixRE = RegExp(r'^\.+([^\.\/]|$)|\/\.+[^\.\/]');

  /// A regexp to filter hidden files (Windows)
  ///
  static final RegExp _hiddenWindowsRE =
      RegExp(r'^\.+([^\.\/\\]|$)|[\/\\]\.+[^\.\/\\]');

  /// A pattern to locate a combination of glob characters which means recursive directory scan
  ///
  static final _isRecursiveGlobPatternRE =
      RegExp(r'\*\*|[\*\?][\/\\]', caseSensitive: false);

  /// Check whether the file system is POSIX-compliant
  ///
  bool get isPosix => (separator == separatorPosix);

  /// A short name of the current directory
  ///
  static const String shortCurDirName = '.';

  /// A short name of the parent directory
  ///
  static const String shortParentDirName = '..';

  /// Replace every [altSeparator] in [path] with [separator]
  /// This is the opposite to `toPosix(...)`
  ///
  String adjust(String? path) {
    if (path == null) {
      return '';
    }
    if (path.isEmpty || altSeparator.isEmpty) {
      return path;
    }
    return path.replaceAll(altSeparator, separator);
  }

  /// Append or remove trailing path separator depending on needs
  ///
  String adjustTrailingSeparator(String? path, FileSystemEntityType type,
      {bool isAppend = false}) {
    if ((path == null) || path.isEmpty) {
      return '';
    }
    if (type != FileSystemEntityType.directory) {
      return path;
    }

    final lastPos = path.length - 1;
    final lastChr = path[lastPos];

    if (lastChr == separator) {
      if (!isPosix) {
        if ((lastPos >= 1) && (path[lastPos - 1] == driveSeparator)) {
          return path;
        }
      }
      return (isAppend ? path : path.substring(0, lastPos));
    } else if ((lastChr == driveSeparator) && isAppend && !isPosix) {
      return path + shortCurDirName + separator;
    }

    return (isAppend ? path + separator : path);
  }

  /// Convert [path] to the fully qualified path\
  /// \
  /// For POSIX, it calls `canonicalize()`\
  /// For Windows, it takes an absolute path,
  /// prepends it with the current drive (if omitted),
  /// and resolves . and ..
  ///
  String getFullPath(String? path) {
    // If path is null or empty, return the current directory
    //
    if ((path == null) || path.isEmpty) {
      return current;
    }

    // Posix is always good
    //
    if (isPosix) {
      return canonicalize(path);
    }

    // Get absolute path
    //
    var absPath = path;

    if (path.startsWith(separator)) {
      if (path[1] == separator) {
        // UNC path should be returned as is
        return path;
      }
      // Path is absolute, but no drive found, so take that from the current directory
      final curDirName = current;
      absPath = curDirName.substring(0, curDirName.indexOf(separator)) + path;
    } else if (!path.contains(PathExt.driveSeparator)) {
      // No drive found, and path is relative, so prepend it with the current directory
      absPath = join(current, path);
    }

    // Resolve . and ..
    //
    return normalize(absPath);
  }

  /// Check whether [path] represents a hidden file or directory:
  /// i.e. [path] contains a sub-dir or a filename starting with
  /// a dot (on either POSIX or Windows)
  ///
  bool isHidden(String path) => (isPosix
      ? _hiddenPosixRE.hasMatch(path)
      : _hiddenWindowsRE.hasMatch(path));

  /// Return true if [path] contains [separator]
  /// If [altSeparator] is not empty, return true also if
  /// [path] contains a non-empty [altSeparator] or [driveSeparator]
  ///
  bool isPath(String? path) {
    if ((path == null) || path.isEmpty) {
      return false;
    }
    if (path.contains(separator)) {
      return true;
    }
    if (altSeparator.isEmpty) {
      return false;
    }
    return (path.contains(altSeparator) || path.contains(driveSeparator));
  }

  /// Check whether the file system is POSIX-compliant
  ///
  bool isRecursive(String? path) =>
      ((path != null) && _isRecursiveGlobPatternRE.hasMatch(path));

  /// Convert [pattern] string into a proper glob object considering the required
  /// file system [fileSystem] and possible extra flags [caseSensitive] and [recursive]
  ///
  Glob toGlob(String? pattern, {bool? caseSensitive, bool? recursive}) => Glob(
      ((pattern == null) || pattern.isEmpty ? PathExt.anyPattern : pattern),
      context: this,
      caseSensitive: caseSensitive ?? equals('A', 'a'),
      recursive: recursive ?? isRecursive(pattern));

  /// Replace every [separator] in [path] with [separatorPosix]
  /// This is the opposite to `adjust(...)`
  ///
  String toPosix(String? path) {
    if (path == null) {
      return '';
    }
    if (path.isEmpty || isPosix) {
      return path;
    }
    return path.replaceAll(separator, separatorPosix);
  }
}

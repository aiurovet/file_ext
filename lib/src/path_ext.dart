// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:path/path.dart' as p;

/// A helper extension for the Path API
///
extension PathExt on p.Context {
  /// Alt directory separator (differs from separator for Windows-style FS only)
  ///
  static const altSeparator = pathSeparatorPosix;

  /// A variant of [altSeparator] for regexp patterns
  ///
  static final altSeparatorEscaped = RegExp.escape(altSeparator);

  /// Const: path separator for POSIX-like filesystems
  ///
  static const pathSeparatorPosix = r'/';

  /// Const: path separator for Windows filesystem
  ///
  static const pathSeparatorWindows = r'\';

  /// Check whether the file system is case-sensitive
  ///
  bool get isCaseSensitive => (separator == altSeparator);

  /// A separator between the drive name and the rest of the path
  /// (relevant to Windows only)
  ///
  static final driveSeparator = r':';

  /// A variant of [driveSeparator] for regexp patterns
  ///
  static final driveSeparatorEscaped = r':';

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
      {bool isAppend = false}) {
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
      return (isAppend ? aPath : aPath.substring(0, lastPos));
    } else if ((lastChr == driveSeparator) && isAppend && !isPosix) {
      return aPath + shortCurDirName + separator;
    }

    return (isAppend ? aPath + separator : aPath);
  }

  /// A pattern to list any file system element
  ///
  static String anyPattern(bool isRecursive) => (isRecursive ? '**' : '*');

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
      return current;
    }

    // If path is empty, return the current directory
    //
    if (aPath.isEmpty) {
      return current;
    }

    // Posix is always 'in chocolate'
    //
    if (isPosix) {
      return canonicalize(aPath);
    }

    // Get absolute path
    //
    var absPath = aPath;

    // If no drive is present, then take it from the current directory
    //
    if (aPath.startsWith(separator)) {
      final curDirName = current;
      absPath = curDirName.substring(0, curDirName.indexOf(separator)) + aPath;
    } else if (!aPath.contains(PathExt.driveSeparator)) {
      absPath = join(current, aPath);
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

Extension methods for filesystem and stdin-related manipulations

## Features

Asynchronous and synchronous extension methods to:

- loop through filesystem entities (filtered by multiple Glob patterns in multiple directories) and call user-defined function
- loop through all memory-based filesystems of all styles and call user-defined function (useful for unit tests)
- loop through lines from stdin and call user-defined function or read the whole stdin
- file path API extension:
  - `adjust()`      - convert all path separators to POSIX style
  - `toPosix()`     - convert all path separators to OS-specific style
  - `getFullPath()` - similar to `canonicalize()`, but preserves letter case
  - `isHidden()`    - check whether a given filename starts with the dot or path contains a sub-directory starting with the dot (but not limited to the dots)
  - `isPath()`      - check whether a given string contains directory component or not

## Usage

The same can be found under the subdirectory `example` of the code repository

```dart
// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_ext/file_ext.dart';
import 'package:glob/glob.dart';
import 'package:intl/intl.dart';
import 'package:parse_args/parse_args.dart';
import 'package:thin_logger/thin_logger.dart';

/// A type for the argument parsing callback functions
///
typedef ParseArgsHandler = void Function(String);

/// Application
///
class Options {
  static const appName = 'file_ext_example';

  /// Count findings only
  ///
  var isCountOnly = false;

  /// Synchronous call flag
  ///
  var isSync = false;

  /// Logger
  ///
  final logger = Logger();

  /// FileSystem
  ///
  final FileSystem fileSystem;

  /// All filters
  ///
  final List<Glob> filters = [];

  /// FileList flags
  ///
  var flags = 0;

  /// Directory to start in
  ///
  final List<String> roots = [];

  /// Entity types to consider
  ///
  final types = <FileSystemEntityType>[];

  /// The actual usage
  ///
  Options(this.fileSystem);

  void parse(List<String> args) {
    logger.info('\nArgs: $args\n');

    var optDefs = '''
      |?,h,help|q,quiet|v,verbose|a,all|d,dir::
      |c,count|L,follow|s,sync|t,type:|::
    ''';

    var opts = parseArgs(optDefs, args);
    logger.levelFromFlags(isQuiet: opts.isSet('q'), isVerbose: opts.isSet('v'));

    if (opts.isSet('?')) {
      printUsage();
    }

    isCountOnly = opts.isSet('k');
    isSync = opts.isSet('s');

    flags = 0;

    if (!opts.isSet('L')) {
      flags |= FileSystemExt.followLinks;
    }

    if (!opts.isSet('a')) {
      flags |= FileSystemExt.allowHidden;
    }

    final typeStr = opts.getStrValue('t')?.toLowerCase();

    if ((typeStr == null) || typeStr.isEmpty || typeStr.contains('d')) {
      types.add(FileSystemEntityType.directory);
    }

    if ((typeStr == null) || typeStr.isEmpty || typeStr.contains('f')) {
      types.add(FileSystemEntityType.file);
    }

    if ((typeStr == null) || typeStr.isEmpty || typeStr.contains('l')) {
      types.add(FileSystemEntityType.link);
    }

    roots.addAll(opts.getStrValues('d'));
    filters.addAll(opts.getGlobValues(''));
  }
}

/// Application singleton
///
final opt = Options(LocalFileSystem());

/// Run single filter
///
Never printUsage() {
  opt.logger.info('''
USAGE:

${Options.appName} [OPTIONS]

OPTIONS:

-d, dir DIR   - directory to start in (default: current)
-c,count      - print count only
-L,follow     - expand symbolic links
-s,sync       - fetch synchronously (blocking mode)
-t,type TYPES - entries to fetch (default - all):
                d - directory
                f - file
                l - link

ARGUMENTS:

One or more glob patterns

EXAMPLES:

${Options.appName} -d /home/user/Downloads -type f ../Documents/**.docx *.txt
''');

   exit(1);
}

/// Entry point
///
void main(List<String> args) async {
  opt.parse(args);

  var count = 0;

  if (opt.isSync) {
    opt.fileSystem.forEachEntitySync(
      roots: opt.roots,
      filters: opt.filters,
      flags: opt.flags,
      types: opt.types,
      entityHandler: (fileSystem, entity, stat) {
        if ((entity == null) || (stat == null)) {
          return true;
        }
        if (opt.isCountOnly) {
          ++count;
        } else {
          var path = fileSystem.path.adjustTrailingSeparator(entity.path, stat.type, isAppend: true);
          if (stat.type == FileSystemEntityType.link) {
            path += ' -> ${fileSystem.file(path).resolveSymbolicLinksSync()}';
          }
          opt.logger.out(path);
        }
        return true;
      },
      exceptionHandler: (fileSystem, entity, stat, exception, stackTrace) {
        opt.logger.error(exception.toString());
        return true; // continue
      });
  } else {
    await opt.fileSystem.forEachEntity(
      roots: opt.roots,
      filters: opt.filters,
      flags: opt.flags,
      types: opt.types,
      entityHandler: (fileSystem, entity, stat) async {
        if ((entity == null) || (stat == null)) {
          return true;
        }
        if (opt.isCountOnly) {
          ++count;
        } else {
          var path = opt.fileSystem.path.adjustTrailingSeparator(entity.path, stat.type, isAppend: true);
          if (stat.type == FileSystemEntityType.link) {
            path += ' -> ${fileSystem.file(path).resolveSymbolicLinksSync()}';
          }
          opt.logger.out(path);
        }
        return true;
      },
      exceptionHandler: (fileSystem, entity, stat, exception, stackTrace) async {
        opt.logger.error(exception.toString());
        return true; // continue
      });
  }

  if (opt.isCountOnly) {
    final value = NumberFormat().format(count);
    final units = (count == 1 ? 'entry' : 'entries');
    opt.logger.out('$value $units found');
  }
}
```

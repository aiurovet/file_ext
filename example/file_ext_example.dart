// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_ext/file_ext.dart';
import 'package:intl/intl.dart';
import 'package:parse_args/parse_args.dart';
import 'package:thin_logger/thin_logger.dart';

/// A type for the argument parsing callback functions
///
typedef ParseArgsHandler = void Function(String);

/// Application
///
class Options {
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
  final filterLists = <FileFilterList>[];

  /// FileList flags
  /// 
  var flags = 0;

  /// Directory to start in
  /// 
  var roots = <String>[];

  /// Entity types to consider
  /// 
  final types = <FileSystemEntityType>[];

  /// The actual usage
  ///
  Options(this.fileSystem);
}

/// Application singleton
/// 
final opt = Options(LocalFileSystem());

/// Entry point
///
void main(List<String> args) async {
  print('\nArgs: $args\n');

  var optDefs = '''
    +|?,h,help|q,quiet|v,verbose|a,all|d,dir::|k,count|L,follow|p,fullpath|s,sync|t,type:
      |::>case,nocase,not,r,regex,regexp,noregex,noregexp
  ''';

  parseArgs(optDefs, args, (isFirstRun, optName, values) {
    // Show details when not on the first run
    //
    if (isFirstRun) {
      parseArgsFirstRun(optName, values);
    } else {
      parseArgsSecondRun(optName, values);
    }
  });

  var count = 0;

  if (opt.isSync) {
    opt.fileSystem.listSync(
        roots: opt.roots,
        filterLists: opt.filterLists,
        flags: opt.flags,
        types: opt.types,
        listHandlerSync: (fileList, item) {
          if (opt.isCountOnly) {
            ++count;
          } else {
            opt.logger.out(opt.fileSystem.path
                .adjustTrailingSeparator(item.path, item.type, isAppend: true));
          }
          return true;
        },
        errorHandler: (fileList, errorInfo) {
          if (errorInfo.item?.path.isNotEmpty ?? false) {
            opt.logger.error((errorInfo.error ?? errorInfo.exception).toString());
          }
          return true; // continue
        });
  } else {
    await opt.fileSystem.list(
        roots: opt.roots,
        filterLists: opt.filterLists,
        flags: opt.flags,
        types: opt.types,
        listHandlerSync: (fileList, item) {
          if (opt.isCountOnly) {
            ++count;
          } else {
            opt.logger.out(opt.fileSystem.path
                .adjustTrailingSeparator(item.path, item.type, isAppend: true));
          }
          return true;
        },
        errorHandler: (fileList, errorInfo) {
          if (errorInfo.item?.path.isNotEmpty ?? false) {
            opt.logger.error((errorInfo.error ?? errorInfo.exception).toString());
          }
          return true; // continue
        });
  }

  if (opt.isCountOnly) {
    final value = NumberFormat().format(count);
    final units = (count == 1 ? 'entry' : 'entries');
    opt.logger.out('$value $units found');
  }
}

/// First iteration of command-line arguments parsing
///
void parseArgsFirstRun(String optName, List values) {
  switch (optName) {
    case 'help':
      // printUsage();
    case 'quiet':
      opt.logger.level = Logger.levelQuiet;
      return;
    case 'verbose':
      opt.logger.level = Logger.levelVerbose;
      return;
  }
}

/// Second iteration of command-line arguments parsing
///
void parseArgsSecondRun(String optName, List values) {
  if (opt.logger.isVerbose) {
    opt.logger.verbose('Option "$optName"${values.isEmpty ? '' : ': $values'}');
  }

  switch (optName) {
    // Patterns
    //
    case '':
      parseFileFilters(values);
      return;
    // List all entries including the hidden ones
    //
    case 'all':
      opt.flags = opt.flags | FileList.allowHidden;
      return;

    // Count only?
    //
    case 'count':
      opt.isCountOnly = true;
      return;

    // Directory to start in
    //
    case 'dir':
      for (final value in values) {
        opt.roots.add(value.toString());
      }
      return;

    // Follow links?
    //
    case 'follow':
      opt.flags |= FileList.followLinks;
      return;

    // Sync calls?
    //
    case 'sync':
      opt.isSync = true;
      return;

    // Filter by one or more types (comma-separated)
    //
    case 'type':
      switch (values.first.toString().toLowerCase()) {
        case 'd':
          opt.types.add(FileSystemEntityType.directory);
          return;
        case 'f':
          opt.types.add(FileSystemEntityType.file);
          return;
        case 'l':
          opt.types.add(FileSystemEntityType.link);
          return;
        default:
          return;
      }
    default:
      throw Exception(
          'Invalid type: "${values[0]}" (expected: "f", "d" or "l")');
  }
}

/// Accumulating filters
///
void parseFileFilters(List values) {
  bool? isCaseSensitive;
  var isNegative = false;
  var isOr = true;
  var isRegular = false;

  final fileSystem = opt.fileSystem;
  final filterLists = opt.filterLists;

  for (final value in values) {
    final pattern = value.toString();

    switch (pattern) {
      case '-and':
        isOr = false;
        continue;
      case '-case':
        isCaseSensitive = true;
        continue;
      case '-nocase':
        isCaseSensitive = false;
        continue;
      case '-not':
        isNegative = true;
        continue;
      case '-or':
        isOr = true;
        continue;
      case '-regexp':
        isRegular = true;
        continue;
      case '-noregexp':
        isRegular = false;
        continue;
      default:
        break;
    }

    final filter = FileFilter(fileSystem, pattern, isCaseSensitive: isCaseSensitive, isNegative: isNegative, isRegular: isRegular);

    if (isOr || filterLists.isEmpty) {
      filterLists.addNew([filter]);
    } else {
      filterLists[filterLists.length - 1].addNew(filter);
    }

    isNegative = false; // applies to the closest pattern only
  }
}

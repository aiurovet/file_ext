// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_ext/file_ext.dart';

import 'print_error_io.dart'
    if (dart.library.html) 'print_error_html.dart';

/// A type for the argument parsing callback functions
///
typedef ParseArgsProc = void Function(String);

/// The actual usage
///
Future printFileList(FileSystem fs, bool allowHidden, String? root,
        List<String>? patterns, FileSystemEntityType? type) async =>
    await fs.list(
        root: root,
        patterns: patterns,
        accumulate: false,
        allowHidden: allowHidden,
        followLinks: true,
        type: type,
        filterProcSync: (entityPath, entityName, stat, options) {
          print(entityPath);
          return true;
        },
        errorProc: (e, stackTrace) {
          printError(e.toString());
        });

/// Entry point
///
void main(List<String> args) async {
  var allowHidden = false;
  var fs = LocalFileSystem();
  String? root;
  var patterns = <String>[];
  FileSystemEntityType? type;

  parseArgs(args, (opt) {
    // Parsing simple options
    //
    switch (opt) {
      case '-a':
      case '--all':
        allowHidden = true;
        return;
      case '-d':
      case '--dirs-only':
        type = FileSystemEntityType.directory;
        return;
      case '-f':
      case '--files-only':
        type = FileSystemEntityType.file;
        return;
    }
  }, (arg) {
    // Parsing plain arguments
    //
    patterns.add(arg);
  });

  await printFileList(fs, allowHidden, root, patterns, type);
}

/// A primitive command-line arguments parser (any other may be used instead)
///
void parseArgs(List<String> args, ParseArgsProc onOpt, ParseArgsProc onArg) {
  for (final arg in args) {
    if (arg.startsWith('-')) {
      onOpt(arg);
    } else {
      onArg(arg);
    }
  }
}

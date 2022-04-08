// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_ext/file_ext.dart';

/// A type for the argument parsing callback functions
///
typedef ParseArgsProc = void Function(String);

/// The actual usage
///
Future printFileList(FileSystem fs, bool allowHidden, String? root,
    List<String>? patterns) async =>
  await fs.list(
    root: root,
    patterns: patterns,
    allowHidden: allowHidden,
    followLinks: true,
    filterProc: (entity, takeText, skipText, options) async {
      if ((await entity.stat()).type == FileSystemEntityType.file) {
        print(entity.path);
      }
      return true;
    },
  );

/// Entry point
///
void main(List<String> args) async {
  var allowHidden = false;
  var fs = LocalFileSystem();
  String? root;
  var patterns = <String>[];

  parseArgs(args, (opt) {
    // Parsing simple options
    //
    switch (opt) {
      case '-a':
      case '--all':
        allowHidden = true;
        return;
    }
  }, (arg) {
    // Parsing plain arguments
    //
    if (root == null) {
      root = arg;
    } else {
      patterns.add(arg);
    }
  });

  await printFileList(fs, allowHidden, root, patterns);
}

/// A primitive command-line arguments parser (any other may be used instead)
///
void parseArgs(List<String> args, ParseArgsProc onOpt, ParseArgsProc onArg) {
  for (var arg in args) {
    if (arg.startsWith('-')) {
      onOpt(arg);
    } else {
      onArg(arg);
    }
  }
}

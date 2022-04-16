// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_ext/file_ext.dart';

import 'print_err_io.dart' if (dart.library.html) 'print_err_html.dart';

/// A type for the argument parsing callback functions
///
typedef ParseArgsProc = void Function(String);

/// The actual usage
///
Future printFileList(FileSystem fileSystem,
        {bool allowHidden = false,
        String? root,
        List<String>? patterns,
        FileSystemEntityType? type,
        bool followLinks = false}) async =>
    await fileSystem.list(
        root: root,
        patterns: patterns,
        accumulate: false,
        allowHidden: allowHidden,
        followLinks: followLinks,
        type: type,
        listProcSync: (fileList, ea) {
          print(fileSystem.path
              .adjustTrailingSeparator(ea.path, ea.type, append: true));
          return true;
        },
        errorProc: (fileList, ea) {
          if (ea.path.isNotEmpty) {
            printErr((ea.error ?? ea.exception).toString());
          }
          return true; // continue
        });

/// Entry point
///
void main(List<String> args) async {
  var allowHidden = false;
  var followLinks = false;
  final fs = LocalFileSystem();
  String? root;
  final patterns = <String>[];
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
      case '--directories-only':
        type = FileSystemEntityType.directory;
        return;
      case '-f':
      case '--files-only':
        type = FileSystemEntityType.file;
        return;
      case '-L':
      case '--follow-links':
        followLinks = true;
        return;
    }
  }, (arg) {
    // Parsing plain arguments
    //
    patterns.add(arg);
  });

  await printFileList(fs,
      allowHidden: allowHidden,
      root: root,
      patterns: patterns,
      type: type,
      followLinks: followLinks);
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

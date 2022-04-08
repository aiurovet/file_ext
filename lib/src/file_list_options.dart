// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';

/// A local class to gather all necessary info for list() and listSync()
///
class FileListOptions {
  /// A glob pattern to not match file and directory paths or names against
  ///
  final List<FileFilter> filters = [];

  /// Should we scan sub-directories or not (as cumulative from filter patterns)
  ///
  late final bool recursive;

  /// A maximum directory not containing wildcards and the other glob elements
  ///
  late final String root;

  /// The constructor
  ///
  FileListOptions(FileSystem fs, {String? root, List<String>? patterns}) {
    var context = fs.path;
    var recursive = false;

    this.root = ((root == null) || root.isEmpty ? context.current : root);

    if (patterns != null) {
      for (var pattern in patterns) {
        var filter = FileFilter(pattern, context: context);

        if (filter.glob?.recursive ?? false) {
          recursive = true;
        }

        filters.add(filter);
      }
    }

    this.recursive = recursive;
  }
}

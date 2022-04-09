// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';
import 'package:path/path.dart' as p;

/// A local class to gather all necessary info for list() and listSync()
///
class FileListOptions {
  /// A regexp to split the input pattern into a list of and-patterns
  ///
  final RegExp andSeparatorRE = RegExp(r'[\s]+[\>]+[\s]*');

  /// A regexp to split the root into a list of top directories
  ///
  final RegExp rootSeparatorRE = RegExp(r'[\s]*[,][\s]*');

  /// A flag indicating whether the file list needs to be accumulated
  ///
  final bool accumulate;

  /// A flag indicating hidden files should be considered or not
  /// (hidden: any sub-directory, other than '.' and '..', or the
  /// basename, starts with '.')
  ///
  final bool allowHidden;

  /// An error handler
  ///
  final FileListErrorProc? errorProc;

  /// The filesystem object
  ///
  final FileSystem fs;

  /// A glob pattern to not match file and directory paths or names against
  ///
  final List<FileFilter> filters = [];

  /// Asynchronous (non-blocking) FileList handler
  /// good for I/O manipulations
  ///
  final FileListProc? filterProc;

  /// Synchronous (blocking) FileList handler
  /// good for path/basename (string) manipulations
  ///
  final FileListProcSync? filterProcSync;

  /// The path object
  ///
  late final p.Context context;

  /// Should we scan sub-directories or not (as cumulative from filter patterns)
  ///
  late final bool recursive;

  /// A list of patterns
  ///
  final List<String> patterns = [];

  /// A list of the longest directories not containing wildcards and the other glob elements
  ///
  final List<String> roots = [];

  /// A list of expected types
  ///
  final List<FileSystemEntityType> types = [];

  /// The constructor
  ///
  FileListOptions(this.fs,
      {String? root,
      List<String>? roots,
      String? pattern,
      List<String>? patterns,
      FileSystemEntityType? type,
      List<FileSystemEntityType>? types,
      this.accumulate = true,
      this.allowHidden = false,
      this.filterProc,
      this.filterProcSync,
      this.errorProc}) {
    context = fs.path;
    var recursive = false;

    // Accumulate all patterns
    //
    if (pattern != null) {
      _splitAndAddPatterns(pattern);
    }
    if (patterns != null) {
      for (var x in patterns) {
        _splitAndAddPatterns(x);
      }
    }

    // Accumulate all roots
    //
    if (root != null) {
      _splitAndAddRoots(root);
    }
    if (roots != null) {
      for (var x in roots) {
        _splitAndAddRoots(x);
      }
    }

    // Gather all types
    //
    if (type != null) {
      this.types.add(type);
    }
    if (types != null) {
      this.types.addAll(types);
    }

    // Split compound pattern list string into plain glob/regexp
    // patterns and create filters
    //
    for (final pattern in this.patterns) {
      var filter = FileFilter(pattern, context: context);

      if (filter.glob?.recursive ?? false) {
        recursive = true;
      }

      filters.add(filter);
    }

    // Set overall recursive flag
    //
    this.recursive = recursive;

    // Merge the root with the primary (first) filter root
    //
    var filter = (filters.isEmpty ? null : filters[0]);

    if (this.roots.isEmpty) {
      if ((filter == null) || filter.root.isEmpty) {
        this.roots.add(context.current);
      } else {
        this.roots.add(filter.root);
        filter.root = '';
      }
    } else if ((filter != null) && filter.root.isNotEmpty) {
      for (var i = 0, n = this.roots.length; i < n; i++) {
        this.roots[i] = fs.path.join(this.roots[i], filter.root);
      }
    }
  }

  /// Returns path or empty string depending on whether the
  /// given path passes `isHidden(...)` test, path and name
  /// match or anti-match every glob and regexp pattern, and
  /// both synchronous and asynchronous user-defined callbacks
  /// return true\
  /// \
  /// If the path represents directory, the return path gets
  /// separator appended if it is not there yet
  ///
  Future<String> getMatchedPath(FileSystemEntity entity,
      {String? path, String? name, FileStat? stat}) async {
    stat ??= await entity.stat();
    path ??= entity.path;
    name ??= context.basename(path);

    final result =
        getMatchedPathSync(entity, path: path, name: name, stat: stat);

    if (result.isNotEmpty && (filterProc != null)) {
      if (!(await filterProc!(path, name, stat, this))) {
        return '';
      }
    }

    return result;
  }

  /// Returns path or empty string depending on whether the
  /// given path passes `isHidden(...)` test, path and name
  /// match or anti-match every glob and regexp pattern, and
  /// synchronous user-defined callback returns true\
  /// \
  /// If the path represents directory, the return path gets
  /// separator appended if it is not there yet
  ///
  String getMatchedPathSync(FileSystemEntity entity,
      {String? path, String? name, FileStat? stat}) {
    path ??= entity.path;

    if (!allowHidden && context.isHidden(path)) {
      return '';
    }

    name ??= context.basename(path);
    stat ??= entity.statSync();

    if (types.isNotEmpty) {
      if (!types.contains(stat.type)) {
        return '';
      }
    }
    for (final filter in filters) {
      if (!filter.matches(path, name)) {
        return '';
      }
    }
    if (filterProcSync != null) {
      if (!filterProcSync!(path, name, stat, this)) {
        return '';
      }
    }

    final sep = context.separator;

    if ((stat.type == FileSystemEntityType.directory) && !path.endsWith(sep)) {
      return path + sep;
    }

    return path;
  }

  /// Split [root] and add to [roots]
  ///
  void _splitAndAddPatterns(String pattern) =>
      patterns.addAll(pattern.split(andSeparatorRE));

  /// Split [root] and add to [roots]
  ///
  void _splitAndAddRoots(String root) =>
      roots.addAll(root.split(rootSeparatorRE));
}

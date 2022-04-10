// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';
import 'package:path/path.dart' as p;

/// A local class to gather all necessary info for list() and listSync()
///
class FileList {
  /// A regexp to split the input pattern into a list of and-patterns
  ///
  final RegExp andSeparatorRE = RegExp(r'\s+>+\s*');

  /// A regexp to split the root into a list of top directories
  ///
  final RegExp rootSeparatorRE = RegExp(r'\s*,\s*');

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
  final FileFilterErrorProc? errorProc;

  /// The filesystem object
  ///
  final FileSystem fs;

  /// A glob pattern to not match file and directory paths or names against
  ///
  final List<FileFilter> filters = [];

  /// Asynchronous (non-blocking) FileList handler
  /// good for I/O manipulations
  ///
  final FileFilterProc? filterProc;

  /// Synchronous (blocking) FileList handler
  /// good for path/basename (string) manipulations
  ///
  final FileFilterProcSync? filterProcSync;

  /// A flag indicating what to do when an entity of the type [Link]
  /// encountered: if true, then replace with the entity it points to
  ///
  final bool followLinks;

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
  FileList(this.fs,
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
      this.errorProc,
      this.followLinks = true}) {
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
      this.roots.add(filter?.root ?? '');
      filter?.root = '';
    } else if ((filter != null) && filter.root.isNotEmpty) {
      for (var i = 0, n = this.roots.length; i < n; i++) {
        this.roots[i] = fs.path.join(this.roots[i], filter.root);
      }
    }
  }

  /// The engine, asynchronous (non-blocking))
  ///
  bool callErrorProc(Object e, StackTrace stackTrace) =>
    (errorProc == null ? true : errorProc!(e, stackTrace));

  /// The engine, asynchronous (non-blocking))
  ///
  Future<List<String>> exec() async {
    var result = <String>[];

    // Accumulate filtered entities
    //
    for (final root in roots) {
      await _exec(result, root);
    }

    return result;
  }

  /// The essential part of `exec(...)`: does everything after the [options]
  /// object created and the next root taken
  ///
  Future<List<String>> _exec(
      List<String> result, String root) async {
    // Retrieve all entites in this directory and don't catch any exception here
    //

    final entities = await fs.directory(root)
        .list(recursive: false, followLinks: followLinks)
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final paths = <String>[];

    for (final entity in entities) {
      try {
        final matchedPath = await getMatchedPath(entity);

        if (matchedPath.isNotEmpty) {
          paths.add(matchedPath);
        }
      } on Error catch (e, stackTrace) {
        if (!callErrorProc(e, stackTrace)) {
          rethrow;
        }
      } on Exception catch (e, stackTrace) {
        if (!callErrorProc(e, stackTrace)) {
          rethrow;
        }
      }
    }

    // Make the access faster
    //
    final sep = fs.path.separator;

    // Add the list of paths under the current root to the result
    // (no sub-directories yet)
    //
    if (accumulate) {
      result.addAll(paths);
    }

    // In case of recursion, call this method again in the loop for each
    // sub-directory
    //
    if (recursive) {
      for (var i = 0, n = paths.length; i < n; i++) {
        final path = paths[i];

        if (path.endsWith(sep)) {
          await _exec(result, path);
        }
      }
    }

    // Return result
    //
    return result;
  }

  /// The engine, synchronous (blocking))
  ///
  List<String> execSync() {
    var result = <String>[];

    // Accumulate filtered entities
    //
    for (final root in roots) {
      _execSync(result, root);
    }

    return result;
  }

  /// The essential part of `execSync(...)`: does everything after the
  /// [options] object created. This separation is needed for recursion
  /// which does require the [options] re-creation
  ///
  List<String> _execSync(
      List<String> result, String root) {
    // Retrieve all entites in this directory and don't catch any exception here
    //
    final entities = fs.directory(root)
        .listSync(recursive: false, followLinks: followLinks)
      ..sort((a, b) => a.path.compareTo(b.path));

    final paths = <String>[];

    for (final entity in entities) {
      try {
        final matchedPath = getMatchedPathSync(entity);

        if (matchedPath.isNotEmpty) {
          paths.add(matchedPath);
        }
      } on Error catch (e, stackTrace) {
        if (!callErrorProc(e, stackTrace)) {
          rethrow;
        }
      } on Exception catch (e, stackTrace) {
        if (!callErrorProc(e, stackTrace)) {
          rethrow;
        }
      }
    }

    // Make the access faster
    //
    final sep = fs.path.separator;

    // Add the list of paths under the current root to the result
    // (no sub-directories yet)
    //
    if (accumulate) {
      result.addAll(paths);
    }

    // In case of recursion, call this method again in the loop for each
    // sub-directory
    //
    if (recursive) {
      for (var i = 0, n = result.length; i < n; i++) {
        final path = result[i];

        if (path.endsWith(sep)) {
          _execSync(result, path);
        }
      }
    }

    // Return result
    //
    return result;
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

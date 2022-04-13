// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';
import 'package:path/path.dart' as p;

/// A local class to gather all necessary info for list() and listSync()
///
class FileList {
  /// A regexp to split the input pattern into a list of and-patterns\
  /// Requires at least one trailing gap (space) between
  /// the character and the actual pattern as well as
  /// suggests the leading one(s)
  ///
  final RegExp andSeparatorRE = RegExp(r'\s+&+\s*');

  /// A regexp to split the root into a list of top directories\
  /// Suggests optional leading and trailing gaps (spaces)
  ///
  final RegExp rootSeparatorRE = RegExp(r'\s*,\s*');

  /// A flag indicating whether the file list needs to be accumulated
  ///
  final bool accumulate;

  /// A flag enabling the use of 'and' and 'not' concepts
  ///
  final bool allowCompoundPatterns;

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
  final FileListProc? listProc;

  /// Synchronous (blocking) FileList handler
  /// good for path/basename (string) manipulations
  ///
  final FileListProcSync? listProcSync;

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
      this.allowCompoundPatterns = true,
      this.allowHidden = false,
      this.followLinks = true,
      this.listProc,
      this.listProcSync,
      this.errorProc}) {
    context = fs.path;
    _addPatterns(pattern, patterns, allowCompoundPatterns);
    _addRoots(root, roots);
    _addTypes(type, types);
    _addFilters();
    _adjustRoots();
  }

  /// The engine, asynchronous (non-blocking))
  ///
  bool callErrorProc(FileSystemEntity? entity, Object e, StackTrace stackTrace) =>
      (errorProc == null ? true : errorProc!(entity, e, stackTrace));

  /// The engine, asynchronous (non-blocking))
  ///
  Future<List<String>> fetch() async {
    var dirNames = <String>[];
    var result = <String>[];

    // Accumulate filtered entities
    //
    for (final root in roots) {
      dirNames = [await fs.directory(root).resolveSymbolicLinks()];
      await _fetch(result, root, dirNames: dirNames);
    }

    return result;
  }

  /// The essential part of `exec(...)`: does everything after the [options]
  /// object created and the next root taken
  ///
  Future<List<String>> _fetch(List<String> result, String root,
      {List<String>? dirNames}) async {
    final List<FileSystemEntity> entities;

    // Retrieve all entites in this directory and don't catch any exception here
    //
    try {
      entities = await fs
          .directory(root.isEmpty ? context.current : root)
          .list(recursive: false, followLinks: followLinks)
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    } on Error catch (e, stackTrace) {
      if (!callErrorProc(null, e, stackTrace)) {
        rethrow;
      }
      return [];
    } on Exception catch (e, stackTrace) {
      if (!callErrorProc(null, e, stackTrace)) {
        rethrow;
      }
      return [];
    }

    final paths = <String>[];

    for (final entity in entities) {
      try {
        final matchedPath = await getMatchedPath(entity, dirNames: dirNames);

        if (matchedPath.isNotEmpty) {
          paths.add(matchedPath);
        }
      } on Error catch (e, stackTrace) {
        if (!callErrorProc(entity, e, stackTrace)) {
          rethrow;
        }
      } on Exception catch (e, stackTrace) {
        if (!callErrorProc(entity, e, stackTrace)) {
          rethrow;
        }
      }
    }

    // Make the access faster
    //
    final sep = context.separator;

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
          await _fetch(result, path, dirNames: dirNames);
        }
      }
    }

    // Return result
    //
    return result;
  }

  /// The engine, synchronous (blocking))
  ///
  List<String> fetchSync() {
    var dirNames = <String>[];
    var result = <String>[];

    // Accumulate filtered entities
    //
    for (final root in roots) {
      dirNames = [fs.directory(root).resolveSymbolicLinksSync()];
      _fetchSync(result, root, dirNames: dirNames);
    }

    return result;
  }

  /// The essential part of `execSync(...)`: does everything after the
  /// [options] object created. This separation is needed for recursion
  /// which does require the [options] re-creation
  ///
  List<String> _fetchSync(List<String> result, String root,
      {List<String>? dirNames}) {
    final List<FileSystemEntity> entities;

    // Retrieve all entites in this directory and don't catch any exception here
    //
    try {
      entities = fs
          .directory(root.isEmpty ? context.current : root)
          .listSync(recursive: false, followLinks: followLinks)
        ..sort((a, b) => a.path.compareTo(b.path));
    } on Error catch (e, stackTrace) {
      if (!callErrorProc(null, e, stackTrace)) {
        rethrow;
      }
      return [];
    } on Exception catch (e, stackTrace) {
      if (!callErrorProc(null, e, stackTrace)) {
        rethrow;
      }
      return [];
    }

    final paths = <String>[];

    for (final entity in entities) {
      try {
        final matchedPath = getMatchedPathSync(entity, dirNames: dirNames);

        if (matchedPath.isNotEmpty) {
          paths.add(matchedPath);
        }
      } on Error catch (e, stackTrace) {
        if (!callErrorProc(entity, e, stackTrace)) {
          rethrow;
        }
      } on Exception catch (e, stackTrace) {
        if (!callErrorProc(entity, e, stackTrace)) {
          rethrow;
        }
      }
    }

    // Make the access faster
    //
    final sep = context.separator;

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
          _fetchSync(result, path, dirNames: dirNames);
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
      {String? path,
      String? name,
      FileStat? stat,
      String? resolved,
      List<String>? dirNames}) async {
    stat ??= await entity.stat();
    path ??= entity.path;
    name ??= context.basename(path);

    final result = getMatchedPathSync(entity,
        path: path, name: name, stat: stat, dirNames: dirNames);

    if (result.isNotEmpty && (listProc != null)) {
      if (!(await listProc!(this, path, name, stat))) {
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
      {String? path,
      String? name,
      FileStat? stat,
      String? resolved,
      List<String>? dirNames}) {
    path ??= entity.path;

    if (!allowHidden && context.isHidden(path)) {
      return '';
    }

    name ??= context.basename(path);
    stat ??= entity.statSync();

    if (types.isNotEmpty && !types.contains(stat.type)) {
      return '';
    }

    var isDirLink = false;

    if (stat.type == FileSystemEntityType.directory) {
      resolved ??= fs.directory(path).resolveSymbolicLinksSync();

      if (dirNames != null) {
        if ((resolved != path) && dirNames.contains(resolved)) {
          isDirLink = true;
        }
        dirNames.add(resolved);
      }
    }
    for (final filter in filters) {
      if (!filter.matches(path, name)) {
        return '';
      }
    }

    final sep = context.separator;

    if ((stat.type == FileSystemEntityType.directory) && !path.endsWith(sep)) {
      path += sep;
    }

    if (!isDirLink || !followLinks) {
      if (listProcSync != null) {
        if (!listProcSync!(this, path, name, stat)) {
          return '';
        }
      }
    }

    return (isDirLink ? '' : path);
  }

  /// Create filters from patterns and accumulate
  ///
  void _addFilters() {
    var recursive = false;

    for (final pattern in patterns) {
      var filter = FileFilter(pattern, context: context);

      if (filter.glob?.recursive ?? false) {
        recursive = true;
      }

      filters.add(filter);
    }

    this.recursive = recursive;
  }

  /// Split every string pattern and accumulate
  ///
  void _addPatterns(String? pattern, List<String>? patterns, bool allowCompoundPatterns) {
    _splitAndAddStrings(this.patterns, pattern, patterns, allowCompoundPatterns);

    if (this.patterns.isEmpty) {
      this.patterns.add(PathExt.anyPattern);
    }
  }

  /// Split every top directory name and accumulate
  ///
  void _addRoots(String? root, List<String>? roots) =>
      _splitAndAddStrings(this.roots, root, roots, false);

  /// Accumulate all filtering types
  ///
  void _addTypes(
      FileSystemEntityType? type, List<FileSystemEntityType>? types) {
    if (type != null) {
      this.types.add(type);
    }
    if (types != null) {
      this.types.addAll(types);
    }
  }

  /// For each root, merge it with the primary (first) filter root
  ///
  void _adjustRoots() {
    if (roots.isEmpty) {
      if (filters.isEmpty) {
        roots.add(PathExt.shortCurDirName);
      } else {
        roots.add(filters[0].root);
        filters[0].root = '';
      }
      return;
    }

    var filter = filters[0];

    if (roots.isEmpty) {
      roots.add(filter.root);
      filters[0].root = '';
      return;
    }

    for (var i = 0, n = roots.length; i < n; i++) {
      filter = filters[i];
      roots[i] = context.join(roots[i], filter.root);
      filter.root = '';
    }
  }

  /// Split every string pattern and add to the destination list
  ///
  void _splitAndAddStrings(List<String> to, String? from, List<String>? froms, bool allowCompoundPatterns) {
    if (from != null) {
      if (allowCompoundPatterns) {
        to.addAll(from.split(andSeparatorRE));
      } else {
        to.add(from);
      }
    }
    if (froms != null) {
      if (allowCompoundPatterns) {
        for (var x in froms) {
          to.addAll(x.split(andSeparatorRE));
        }
      } else {
        to.addAll(froms);
      }
    }
  }
}

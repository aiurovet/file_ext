// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';
import 'package:file_ext/src/file_list_entity_event_args.dart';
import 'package:file_ext/src/file_list_error_event_args.dart';
import 'package:path/path.dart' as p;

/// A local class to gather all necessary info for list() and listSync()
///
class FileList {
  /// A regexp to split the root into a list of top directories\
  /// Suggests optional leading and trailing gaps (spaces)
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

  /// A flag indicating whether filtering is case-sensitive or not, or OS-specific
  ///
  final bool? caseSensitive;

  /// An error handler
  ///
  final FileListErrorProc? errorProc;

  /// The filesystem object
  ///
  final FileSystem fileSystem;

  /// A list of straight filters created based on the list of FilePatterns\
  /// Gets populated on `fetch()` or `fetchSync()` call
  ///
  final List<FileFilter> straightFilters = [];

  /// A list of inverse filters created based on the list of FilePatterns\
  /// Gets populated on `fetch()` or `fetchSync()` call
  ///
  final List<FileFilter> inverseFilters = [];

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
  late final p.Context path;

  /// Should we scan sub-directories or not (as cumulative from filter patterns)
  ///
  var recursive = false;

  /// A list of patterns
  ///
  final List<FilePattern> patterns = [];

  /// A list of the longest directories not containing wildcards and the other glob elements
  ///
  final List<String> roots = [];

  /// A list of expected types
  ///
  final List<FileSystemEntityType> types = [];

  /// The constructor
  ///
  FileList(this.fileSystem,
      {String? root,
      List<String>? roots,
      FilePattern? pattern,
      List<FilePattern>? patterns,
      FileSystemEntityType? type,
      List<FileSystemEntityType>? types,
      this.caseSensitive,
      this.accumulate = true,
      this.allowHidden = false,
      this.followLinks = true,
      this.listProc,
      this.listProcSync,
      this.errorProc}) {
    path = fileSystem.path;
    _addPatterns(pattern, patterns);
    _addRoots(root, roots);
    _addTypes(type, types);
  }

  /// Call error handler if it is set
  ///
  bool callErrorProc(FileListEntityEventArgs? entityArgs, Error? error,
      Exception? exception, StackTrace stackTrace) {
    if (errorProc == null) {
      return true;
    }
    return errorProc!(
        this,
        FileListErrorEventArgs(
            entityArgs: entityArgs,
            error: error,
            exception: exception,
            stackTrace: stackTrace));
  }

  /// The engine, asynchronous (non-blocking)
  ///
  Future<List<String>> fetch() async {
    await setFilters();

    final visitedDirNames = <String>[];
    var result = <String>[];

    // Accumulate filtered entities
    //
    for (final root in roots) {
      for (final straightFilter in straightFilters) {
        final subDirName = straightFilter.dirName;
        final subRoot = path.join(root, subDirName);

        recursive = straightFilter.glob?.recursive ?? false;
        straightFilter.dirName = '';

        visitedDirNames.clear();

        if (subRoot.isEmpty) {
          visitedDirNames.add(subRoot);
        } else {
          visitedDirNames.add(
            await fileSystem.directory(subRoot).resolveSymbolicLinks()
          );
        }

        await _fetch(result, subRoot, straightFilter, visitedDirNames);

        straightFilter.dirName = subDirName;
      }
    }

    return result;
  }

  /// The engine, synchronous (blocking)
  ///
  List<String> fetchSync() {
    setFiltersSync();

    final visitedDirNames = <String>[];
    var result = <String>[];

    // Accumulate filtered entities
    //
    for (final root in roots) {
      for (final straightFilter in straightFilters) {
        final subDirName = straightFilter.dirName;
        final subRoot = path.join(root, subDirName);

        recursive = straightFilter.glob?.recursive ?? false;
        straightFilter.dirName = '';

        if (subRoot.isEmpty) {
          visitedDirNames.add(subRoot);
        } else {
          visitedDirNames.add(
            fileSystem.directory(subRoot).resolveSymbolicLinksSync()
          );
        }

        _fetchSync(result, subRoot, straightFilter, visitedDirNames);

        straightFilter.dirName = subDirName;
      }
    }

    return result;
  }

  /// Returns true if the given path passes `isHidden(...)` test, and\
  /// path and name match specific straight filter as well as every inverse filter
  ///
  bool getMatchedPath(FileListEntityEventArgs entityArgs,
      FileFilter straightFilter, List<String> visitedDirNames) {
    if ((!allowHidden && path.isHidden(entityArgs.path)) ||
        (types.isNotEmpty && !types.contains(entityArgs.stat?.type))) {
      return false;
    }

    if (!straightFilter.matches(entityArgs.path, entityArgs.baseName)) {
      return false;
    }

    for (final inverseFilter in inverseFilters) {
      if (!inverseFilter.matches(entityArgs.path, entityArgs.baseName)) {
        return false;
      }
    }

    return true;
  }

  /// Returns true if the given path passes `isHidden(...)` test,\
  /// path and name match or anti-match every glob and regexp pattern,\
  /// and both synchronous and asynchronous user-defined callbacks
  /// return true (async)
  ///
  Future<bool> getMatchedPathAndCallProc(FileListEntityEventArgs entityArgs,
      FileFilter straightFilter, List<String> visitedDirNames) async {
    final isNewDir = await entityArgs.isNewDirectory(visitedDirNames);

    if (isNewDir != null) {
      if (!isNewDir) {
        return false;
      }
      if (recursive) {
        return true;
      }
    }
    if (!getMatchedPath(entityArgs, straightFilter, visitedDirNames)) {
      return false;
    }
    if (entityArgs.isLink && followLinks) {
      if (entityArgs.type == FileSystemEntityType.directory) {
        return false;
      }
    }
    if (listProcSync != null) {
      if (!listProcSync!(this, entityArgs)) {
        return false;
      }
    }
    if (listProc != null) {
      if (!(await listProc!(this, entityArgs))) {
        return false;
      }
    }
    return true;
  }

  /// Returns true if the given path passes `isHidden(...)` test,\
  /// path and name match or anti-match every glob and regexp pattern,\
  /// and synchronous user-defined callback returns true (sync)
  ///
  bool getMatchedPathAndCallProcSync(FileListEntityEventArgs entityArgs,
      FileFilter straightFilter, List<String> visitedDirNames) {
    final isNewDir = entityArgs.isNewDirectorySync(visitedDirNames);

    if (isNewDir != null) {
      if (!isNewDir) {
        return false;
      }
      if (recursive) {
        return true;
      }
    }
    if (!getMatchedPath(entityArgs, straightFilter, visitedDirNames)) {
      return false;
    }
    if (entityArgs.isLink && followLinks) {
      if (entityArgs.type == FileSystemEntityType.directory) {
        return false;
      }
    }
    if (listProcSync != null) {
      if (!listProcSync!(this, entityArgs)) {
        return false;
      }
    }
    return true;
  }

  /// Create filters from patterns and accumulate
  ///
  Future setFilters() async {
    for (final pattern in patterns) {
      var filter = FileFilter(fileSystem);
      await filter.setPattern(pattern);

      if (filter.inverse) {
        inverseFilters.add(filter);
      } else {
        straightFilters.add(filter);
      }
    }
  }

  /// Create filters from patterns and accumulate
  ///
  void setFiltersSync() {
    for (final pattern in patterns) {
      var filter = FileFilter(fileSystem);
      filter.setPatternSync(pattern);

      if (filter.inverse) {
        inverseFilters.add(filter);
      } else {
        straightFilters.add(filter);
      }
    }
  }

  /// Split every string pattern and add to the destination list
  ///
  void _addAll<T>(List<T> to, T? from, List<T>? froms) {
    if (from != null) {
      to.add(from);
    }
    if (froms != null) {
      to.addAll(froms);
    }
  }

  /// Split every string pattern and accumulate
  ///
  void _addPatterns(FilePattern? pattern, List<FilePattern>? patterns) {
    _addAll(this.patterns, pattern, patterns);

    if (this.patterns.isEmpty) {
      this.patterns.add(FilePattern.any);
    }
  }

  /// Split every top directory name and accumulate
  ///
  void _addRoots(String? root, List<String>? roots) {
    _addAll(this.roots, root, roots);

    if (this.roots.isEmpty) {
      this.roots.add('');
    }
  }

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

  /// The essential part of `exec(...)`: does everything after the [options]
  /// object created and the next root taken
  ///
  Future<List<String>> _fetch(List<String> result, String root,
      FileFilter straightFilter, List<String> visitedDirNames) async {
    final List<FileSystemEntity> entities;

    // Retrieve all entites in this directory and don't catch any exception here
    //
    try {
      entities = await fileSystem
          .directory(root)
          .list(recursive: false, followLinks: followLinks)
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    } on Error catch (e, stackTrace) {
      if (!callErrorProc(null, e, null, stackTrace)) {
        rethrow;
      }
      return [];
    } on Exception catch (e, stackTrace) {
      if (!callErrorProc(null, null, e, stackTrace)) {
        rethrow;
      }
      return [];
    }

    // Loop through the list of obtained entities and add matched paths
    //
    final paths = <String>[];
    final entityTypes = <FileSystemEntityType>[];

    final entityArgs = FileListEntityEventArgs(
        fileSystem: fileSystem, canRemoveCurDirName: root.isEmpty);

    for (final entity in entities) {
      try {
        await entityArgs.fetch(entity, followLinks);

        if (await getMatchedPathAndCallProc(
            entityArgs, straightFilter, visitedDirNames)) {
          paths.add(entityArgs.path);
          entityTypes.add(entityArgs.type);
        }
      } on Error catch (e, stackTrace) {
        if (!callErrorProc(entityArgs, e, null, stackTrace)) {
          rethrow;
        }
      } on Exception catch (e, stackTrace) {
        if (!callErrorProc(entityArgs, null, e, stackTrace)) {
          rethrow;
        }
      }
    }

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

        if (entityTypes[i] == FileSystemEntityType.directory) {
          await _fetch(result, path, straightFilter, visitedDirNames);
        }
      }
    }

    // Return the result
    //
    return result;
  }

  /// The essential part of `execSync(...)`: does everything after the
  /// [options] object created. This separation is needed for recursion
  /// which does require the [options] re-creation
  ///
  List<String> _fetchSync(List<String> result, String root,
      FileFilter straightFilter, List<String> visitedDirNames) {
    final List<FileSystemEntity> entities;

    // Retrieve all entites in this directory and don't catch any exception here
    //
    try {
      entities = fileSystem
          .directory(root)
          .listSync(recursive: false, followLinks: followLinks)
        ..sort((a, b) => a.path.compareTo(b.path));
    } on Error catch (e, stackTrace) {
      if (!callErrorProc(null, e, null, stackTrace)) {
        rethrow;
      }
      return [];
    } on Exception catch (e, stackTrace) {
      if (!callErrorProc(null, null, e, stackTrace)) {
        rethrow;
      }
      return [];
    }

    // Loop through the list of obtained entities and add matched paths
    //
    final paths = <String>[];

    final entityArgs = FileListEntityEventArgs(
        fileSystem: fileSystem, canRemoveCurDirName: root.isEmpty);

    for (final entity in entities) {
      try {
        entityArgs.fetchSync(entity, followLinks);

        if (getMatchedPathAndCallProcSync(
            entityArgs, straightFilter, visitedDirNames)) {
          paths.add(path.adjustTrailingSeparator(
              entityArgs.path, entityArgs.type,
              append: true));
        }
      } on Error catch (e, stackTrace) {
        if (!callErrorProc(entityArgs, e, null, stackTrace)) {
          rethrow;
        }
      } on Exception catch (e, stackTrace) {
        if (!callErrorProc(entityArgs, null, e, stackTrace)) {
          rethrow;
        }
      }
    }

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
      final sep = path.separator;

      for (var i = 0, n = paths.length; i < n; i++) {
        final path = paths[i];

        if (path.endsWith(sep)) {
          _fetchSync(result, path, straightFilter, visitedDirNames);
        }
      }
    }

    // Return the result
    //
    return result;
  }
}

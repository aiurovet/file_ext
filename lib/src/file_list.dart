// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';
import 'package:path/path.dart' as p;

/// A local class to gather all necessary info for list() and listSync()
///
class FileList {
  /// Const flag: accumulate filtering results into a total list
  ///
  static const accumulate = (1 << 0);

  /// Const flag: Include POSIX-hidden files into result list
  ///
  static const allowHidden = (1 << 1);

  /// Expand links into actual directories or files
  ///
  static const followLinks = (1 << 2);

  /// An error handler
  ///
  final FileListErrorHandler? errorHandler;

  /// The filesystem object
  ///
  final FileSystem fileSystem;

  /// Or-list of and-lists of filters
  ///
  final FileFilterLists filterLists = [];

  /// Combination of const flags listed at the top
  ///
  final int flags;

  /// Asynchronous (non-blocking) FileList handler
  /// good for I/O manipulations
  ///
  final FileListHandler? listHandler;

  /// Synchronous (blocking) FileList handler
  /// good for path/basename (string) manipulations
  ///
  final FileListHandlerSync? listHandlerSync;

  /// The path object
  ///
  late final p.Context path;

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
      FileFilter? filter,
      FileFilterList? filterList,
      FileFilterLists? filterLists,
      FileSystemEntityType? type,
      List<FileSystemEntityType>? types,
      this.flags = followLinks,
      this.listHandler,
      this.listHandlerSync,
      this.errorHandler}) {
    path = fileSystem.path;
    _addRoots(root, roots);
    _addTypes(type, types);
    _addFilters(filter, filterList, filterLists);
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

  /// Add all filters
  ///
  void _addFilters(FileFilter? filter, FileFilterList? filterList,
      FileFilterLists? filterLists) {
    if (filter != null) {
      this.filterLists.addNew([filter]);
    }
    if ((filterList != null) && filterList.isNotEmpty) {
      this.filterLists.addNew(filterList);
    }
    if ((filterLists != null) && filterLists.isNotEmpty) {
      this.filterLists.addAllNew(filterLists);
    }
    if (this.filterLists.isEmpty) {
      this.filterLists.addNew([FileFilter.any(fileSystem)]);
    } else {
      for (final filterList in this.filterLists) {
        filterList.normalize(fileSystem);
      }
    }
  }

  /// Call error handler if it is set
  ///
  bool callErrorHandler(Error? error, Exception? exception,
      StackTrace stackTrace, FileListItem? item, String prevWorkDirName) {
    var result = true;

    if (errorHandler != null) {
      result = errorHandler!(
          this,
          FileListErrorInfo(
              item: item,
              error: error,
              exception: exception,
              stackTrace: stackTrace));
    }

    if (prevWorkDirName.isNotEmpty &&
        (prevWorkDirName != PathExt.shortCurDirName)) {
      fileSystem.currentDirectory = prevWorkDirName;
    }

    return result;
  }

  /// The engine, asynchronous (non-blocking)
  ///
  Future<List<String>> fetch() async {
    final prevWorkDirName = fileSystem.currentDirectory.path;
    final result = <String>[];

    for (final root in roots) {
      final isTrimCurDirName = root.isEmpty;

      if (!isTrimCurDirName && !path.equals(root, PathExt.shortCurDirName)) {
        fileSystem.currentDirectory = root;
      }

      for (final filters in filterLists) {
        await _fetch(result, filters, isTrimCurDirName, prevWorkDirName);
      }
    }

    fileSystem.currentDirectory = prevWorkDirName;

    return result;
  }

  /// The essential part of `exec(...)`: does everything after the [options]
  /// object created and the next root taken
  ///
  Future<List<String>> _fetch(List<String> result, FileFilterList filters,
      bool isTrimCurDirName, String prevWorkDirName) async {
    final Stream<FileSystemEntity> entities;

    // Retrieve all entites in this directory and don't catch any exception here
    //
    try {
      final glob = (await filters[0].adjust(fileSystem)).glob!;
      final isFollowLinks = ((flags & followLinks) != 0);
      entities = glob.listFileSystem(fileSystem, followLinks: isFollowLinks);
    } on Error catch (e, stackTrace) {
      if (!callErrorHandler(e, null, stackTrace, null, prevWorkDirName)) {
        rethrow;
      }
      return [];
    } on Exception catch (e, stackTrace) {
      if (!callErrorHandler(null, e, stackTrace, null, prevWorkDirName)) {
        rethrow;
      }
      return [];
    }

    // Loop through the list of obtained entities and add matched ones
    //
    final filterCount = filters.length;
    final hasTypes = types.isNotEmpty;
    final isAccumulate = ((flags & accumulate) != 0);
    final isAllowHidden = ((flags & allowHidden) != 0);
    final item = FileListItem(fileSystem, isTrimCurDirName: isTrimCurDirName);

    await for (final entity in entities) {
      try {
        if (!isAllowHidden && path.isHidden(entity.path)) {
          continue;
        }

        await item.fetch(entity, ((flags & followLinks) != 0));

        if (hasTypes && !types.contains(item.type)) {
          break;
        }

        var hasMatch = true;

        for (var i = 1; i < filterCount; i++) {
          if (!filters[i].hasMatch(item.posixPath, item.baseName)) {
            hasMatch = false;
            break;
          }
        }

        if (!hasMatch) {
          continue;
        }

        if (listHandlerSync != null) {
          if (!listHandlerSync!(this, item)) {
            break;
          }
        }
        if (listHandler != null) {
          if (!(await listHandler!(this, item))) {
            break;
          }
        }
        if (isAccumulate) {
          result.add(item.path);
        }
      } on Error catch (e, stackTrace) {
        if (!callErrorHandler(e, null, stackTrace, item, prevWorkDirName)) {
          rethrow;
        }
      } on Exception catch (e, stackTrace) {
        if (!callErrorHandler(null, e, stackTrace, item, prevWorkDirName)) {
          rethrow;
        }
      }
    }

    return result;
  }

  /// The engine, synchronous (blocking)
  ///
  List<String> fetchSync() {
    final prevWorkDirName = fileSystem.currentDirectory.path;
    final result = <String>[];

    // Fetch all directory and file names matching given filters
    //
    for (final root in roots) {
      final isTrimCurDirName = root.isEmpty;

      if (!isTrimCurDirName && !path.equals(root, PathExt.shortCurDirName)) {
        fileSystem.currentDirectory = root;
      }

      for (final filters in filterLists) {
        _fetchSync(result, filters, isTrimCurDirName, prevWorkDirName);
      }
    }

    fileSystem.currentDirectory = prevWorkDirName;

    return result;
  }

  /// The essential part of `execSync(...)`: does everything after the
  /// [options] object created. This separation is needed for recursion
  /// which does require the [options] re-creation
  ///
  List<String> _fetchSync(List<String> result, FileFilterList filters,
      bool isTrimCurDirName, String prevWorkDirName) {
    final List<FileSystemEntity> entities;

    // Retrieve all entites in this directory and don't catch any exception here
    //
    try {
      final glob = filters[0].adjustSync(fileSystem).glob!;
      final isFollowLinks = ((flags & followLinks) != 0);
      entities =
          glob.listFileSystemSync(fileSystem, followLinks: isFollowLinks);
    } on Error catch (e, stackTrace) {
      if (!callErrorHandler(e, null, stackTrace, null, prevWorkDirName)) {
        rethrow;
      }
      return [];
    } on Exception catch (e, stackTrace) {
      if (!callErrorHandler(null, e, stackTrace, null, prevWorkDirName)) {
        rethrow;
      }
      return [];
    }

    // Loop through the list of obtained entities and add matched ones
    //
    final filterCount = filters.length;
    final hasTypes = types.isNotEmpty;
    final isAccumulate = ((flags & accumulate) != 0);
    final isAllowHidden = ((flags & allowHidden) != 0);
    final item = FileListItem(fileSystem, isTrimCurDirName: isTrimCurDirName);

    for (final entity in entities) {
      try {
        if (!isAllowHidden && path.isHidden(entity.path)) {
          continue;
        }

        item.fetchSync(entity, ((flags & followLinks) != 0));

        if (hasTypes && !types.contains(item.type)) {
          continue;
        }

        var hasMatch = true;

        for (var i = 1; i < filterCount; i++) {
          if (!filters[i].hasMatch(item.posixPath, item.baseName)) {
            hasMatch = false;
            break;
          }
        }

        if (!hasMatch) {
          continue;
        }

        if (listHandlerSync != null) {
          if (!listHandlerSync!(this, item)) {
            break;
          }
        }

        if (isAccumulate) {
          result.add(item.path);
        }
      } on Error catch (e, stackTrace) {
        if (!callErrorHandler(e, null, stackTrace, item, prevWorkDirName)) {
          rethrow;
        }
      } on Exception catch (e, stackTrace) {
        if (!callErrorHandler(null, e, stackTrace, item, prevWorkDirName)) {
          rethrow;
        }
      }
    }

    return result;
  }
}

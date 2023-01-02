// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';
import 'package:glob/glob.dart';

/// A helper extension for the FileSystem API
///
extension FileSystemExt on FileSystem {
  /// Const flag: accumulate filtering results into a total list
  ///
  static const accumulate = (1 << 0);

  /// Const flag: Include POSIX-hidden files into result list
  ///
  static const allowHidden = (1 << 1);

  /// Expand links into actual directories or files
  ///
  static const followLinks = (1 << 2);

  /// Traverse directories and files and call handlers (non-blocking)
  ///
  Future<Set<String>> forEachEntity(
      {String? root,
      List<String>? roots,
      Glob? filter,
      List<Glob>? filters,
      FileSystemEntityType? type,
      List<FileSystemEntityType>? types,
      int flags = followLinks,
      FileSystemEntityHandler? entityHandler,
      FileSystemEntityHandlerSync? entityHandlerSync,
      FileSystemEntityExceptionHandler? exceptionHandler,
      FileSystemEntityExceptionHandlerSync? exceptionHandlerSync}) async {
    final orgRoot = currentDirectory.path;
    final theRoots = _getRoots(root, roots);
    final theFilters = _getFilters(filter, filters);
    final theTypes = _getTypes(type, types);
    final result = <String>{};

    var isAccumulate = ((flags & accumulate) != 0);
    var isAllTypes = theTypes.isEmpty;
    var isFollowLinks = ((flags & followLinks) != 0);
    var isHiddenAllowed = ((flags & allowHidden) != 0);

    Stream<FileSystemEntity> entities;
    FileStat? stat;

    for (var theFilter in theFilters) {
      for (var theRoot in theRoots) {
        try {
          final curRoot = (theRoot.isEmpty ? orgRoot : theRoot);
          entities = theFilter.listFileSystem(this,
              root: curRoot, followLinks: isFollowLinks);
        } on Exception catch (e, stackTrace) {
          if (exceptionHandlerSync != null) {
            if (!exceptionHandlerSync(this, null, null, e, stackTrace)) {
              rethrow;
            }
          }
          if (exceptionHandler != null) {
            if (!(await exceptionHandler(this, null, null, e, stackTrace))) {
              rethrow;
            }
          }
          return result;
        }

        await for (var entity in entities) {
          try {
            if (!isHiddenAllowed && path.isHidden(entity.path)) {
              continue;
            }

            stat = await entity.stat();

            if (!isAllTypes && !theTypes.contains(stat.type)) {
              continue;
            }
            if (entityHandlerSync != null) {
              if (!entityHandlerSync(this, entity, stat)) {
                break;
              }
            }
            if (entityHandler != null) {
              if (!await entityHandler(this, entity, stat)) {
                break;
              }
            }
            if (isAccumulate) {
              result.add(entity.path);
            }
          } on Exception catch (e, stackTrace) {
            if (exceptionHandlerSync != null) {
              if (!exceptionHandlerSync(this, null, null, e, stackTrace)) {
                rethrow;
              }
            }
            if (exceptionHandler != null) {
              if (!(await exceptionHandler(
                  this, entity, stat, e, stackTrace))) {
                rethrow;
              }
            }
          }
        }
      }
    }

    return result;
  }

  /// Traverse directories and files and call handlers (blocking)
  ///
  Set<String> forEachEntitySync(
      {String? root,
      List<String>? roots,
      Glob? filter,
      List<Glob>? filters,
      FileSystemEntityType? type,
      List<FileSystemEntityType>? types,
      int flags = followLinks,
      FileSystemEntityHandlerSync? entityHandler,
      FileSystemEntityExceptionHandlerSync? exceptionHandler}) {
    final orgRoot = currentDirectory.path;
    final theRoots = _getRoots(root, roots);
    final theFilters = _getFilters(filter, filters);
    final theTypes = _getTypes(type, types);
    final result = <String>{};

    var isAccumulate = ((flags & accumulate) != 0);
    var isAllTypes = theTypes.isEmpty;
    var isFollowLinks = ((flags & followLinks) != 0);
    var isHiddenAllowed = ((flags & allowHidden) != 0);

    List<FileSystemEntity> entities;
    FileStat? stat;

    for (var theFilter in theFilters) {
      for (var theRoot in theRoots) {
        try {
          final curRoot = (theRoot.isEmpty ? orgRoot : theRoot);
          entities = theFilter.listFileSystemSync(this,
              root: curRoot, followLinks: isFollowLinks);
        } on Exception catch (e, stackTrace) {
          if (exceptionHandler != null) {
            if (!exceptionHandler(this, null, null, e, stackTrace)) {
              rethrow;
            }
          }
          return result;
        }

        for (var entity in entities) {
          try {
            if (!isHiddenAllowed && path.isHidden(entity.path)) {
              continue;
            }

            stat = entity.statSync();

            if (!isAllTypes && !theTypes.contains(stat.type)) {
              continue;
            }

            if (entityHandler != null) {
              if (!entityHandler(this, entity, stat)) {
                break;
              }
            }

            if (isAccumulate) {
              result.add(entity.path);
            }
          } on Exception catch (e, stackTrace) {
            if (exceptionHandler != null) {
              if (!exceptionHandler(this, entity, stat, e, stackTrace)) {
                rethrow;
              }
            }
          }
        }
      }
    }

    return result;
  }

  /// Get the list of all filter lists
  ///
  Set<Glob> _getFilters(Glob? filter, List<Glob>? filters) {
    var result = <Glob>{};

    if (filter != null) {
      result.add(filter);
    }

    if ((filters != null) && filters.isNotEmpty) {
      result.addAll(filters);
    }

    if (result.isEmpty) {
      result.add(Glob(PathExt.anyPattern));
    }

    return result;
  }

  /// Get the list of all root directorty names
  ///
  Set<String> _getRoots(String? root, List<String>? roots) {
    var result = <String>{};

    if (root != null) {
      result.add(root);
    }

    if ((roots != null) && roots.isNotEmpty) {
      result.addAll(roots);
    }

    if (result.isEmpty) {
      result.add(path.current);
    }

    return result;
  }

  /// Get the list of all expected types
  ///
  Set<FileSystemEntityType> _getTypes(
      FileSystemEntityType? type, List<FileSystemEntityType>? types) {
    var result = <FileSystemEntityType>{};

    if (type != null) {
      result.add(type);
    }

    if ((types != null) && types.isNotEmpty) {
      result.addAll(types);
    }

    return result;
  }
}

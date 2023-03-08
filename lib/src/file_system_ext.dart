// Copyright (c) 2022-2023, Alexander Iurovetski
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
      FileSystemEntityHandler? onEntity,
      FileSystemEntityExceptionHandler? onException}) async {
    final orgRoot = currentDirectory.path;
    final theRoots = _getRoots(root, roots);
    final theFilters = _getFilters(filter, filters);
    final theTypes = _getTypes(type, types);
    final result = <String>{};

    var isAccumulate = ((flags & accumulate) != 0);
    var isAllTypes = theTypes.isEmpty;
    var isFollowLinks = ((flags & followLinks) != 0);
    var isHiddenAllowed = ((flags & allowHidden) != 0);

    final isOnEntitySync = (onEntity is FileSystemEntityHandlerSync);
    final isOnExceptionSync =
        (onException is FileSystemEntityExceptionHandlerSync);

    Stream<FileSystemEntity> entities;
    FileStat? stat;

    for (var theFilter in theFilters) {
      for (var theRoot in theRoots) {
        try {
          final curRoot = (theRoot.isEmpty ? orgRoot : theRoot);
          entities = theFilter.listFileSystem(this,
              root: curRoot, followLinks: isFollowLinks);
        } on Exception catch (e, stackTrace) {
          if (onException != null) {
            if (isOnExceptionSync) {
              if (onException(this, null, null, e, stackTrace).isStop) {
                rethrow;
              }
            } else if ((await onException(this, null, null, e, stackTrace))
                .isStop) {
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
            if (onEntity != null) {
              if (isOnEntitySync) {
                if (onEntity(this, entity, stat).isStop) {
                  break;
                }
              } else if ((await onEntity(this, entity, stat)).isStop) {
                break;
              }
            }
            if (isAccumulate) {
              result.add(entity.path);
            }
          } on Exception catch (e, stackTrace) {
            if (onException != null) {
              if (isOnExceptionSync) {
                if (onException(this, entity, stat, e, stackTrace).isStop) {
                  rethrow;
                }
              } else if ((await onException(this, entity, stat, e, stackTrace))
                  .isStop) {
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
      FileSystemEntityHandlerSync? onEntity,
      FileSystemEntityExceptionHandlerSync? onException}) {
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
          if (onException != null) {
            if (onException(this, null, null, e, stackTrace).isStop) {
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

            if (onEntity != null) {
              if (onEntity(this, entity, stat).isStop) {
                break;
              }
            }

            if (isAccumulate) {
              result.add(entity.path);
            }
          } on Exception catch (e, stackTrace) {
            if (onException != null) {
              if (onException(this, entity, stat, e, stackTrace).isStop) {
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

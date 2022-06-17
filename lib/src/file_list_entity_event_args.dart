// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';

/// FileList event details
///
class FileListEntityEventArgs {
  /// The filename
  ///
  String baseName = '';

  /// The flag indicating the entity is actually a directory link
  ///
  bool isLink = false;

  /// The entity path
  ///
  String path = '';

  /// The source file system entity object
  ///
  FileSystemEntity? source;

  /// The file or directory stat
  ///
  FileStat? stat;

  /// A separate property for the entity type to avoid
  /// permanent coalescing
  ///
  FileSystemEntityType type = FileSystemEntityType.notFound;

  /// The constructor populating all properties
  ///
  FileListEntityEventArgs();

  /// The deep copy
  ///
  void copyFrom(FileListEntityEventArgs? rhs) {
    if (rhs != null) {
      baseName = rhs.baseName;
      isLink = rhs.isLink;
      path = rhs.path;
      source = rhs.source;
      stat = rhs.stat;
      type = rhs.type;
    }
  }

  /// Fetch the entity details (async)
  ///
  Future fetch(FileSystemEntity entity, bool listFollowsLinks) async =>
      _fetch(entity, listFollowsLinks, await entity.stat());

  /// Fetch the entity details (sync)
  ///
  void fetchSync(FileSystemEntity entity, bool listFollowsLinks) =>
      _fetch(entity, listFollowsLinks, entity.statSync());

  /// Fetch the entity details (common)
  ///
  void _fetch(FileSystemEntity entity, bool listFollowsLinks, FileStat stat) {
    baseName = entity.basename;
    path = entity.path;
    source = entity;
    this.stat = stat;
    type = stat.type;
    isLink = (listFollowsLinks ? false : (entity is Link));
  }

  /// Check whether a directory needs to be scanned by looking up
  /// its real path in the list of processed directories (async)\
  /// Currently a bug or a feature in `dart:io` and `file.dart`,
  /// the links to directories are always reported with type directory
  ///
  Future<bool?> isNewDirectory(List<String> dirNames) async =>
      (type != FileSystemEntityType.directory
          ? null
          : _isNewDirectory(dirNames, await source?.resolveSymbolicLinks()));

  /// Check whether a directory needs to be scanned by looking up
  /// its real path in the list of processed directories (sync)\
  /// Currently a bug or a feature in `dart:io` and `file.dart`,
  /// the links to directories are always reported with type directory
  ///
  bool? isNewDirectorySync(List<String> dirNames) =>
      (type != FileSystemEntityType.directory
          ? null
          : _isNewDirectory(dirNames, source?.resolveSymbolicLinksSync()));

  /// Check whether a directory needs to be scanned by looking up
  /// a given real path in the list of processed directories
  ///
  bool _isNewDirectory(List<String> dirNames, String? newDirName) {
    if ((newDirName == null) || newDirName.isEmpty) {
      return false;
    }

    if (dirNames.contains(newDirName)) {
      return false;
    }

    dirNames.add(newDirName);

    return true;
  }
}

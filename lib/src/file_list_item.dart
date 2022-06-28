// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';

/// FileList event details
///
class FileListItem {
  /// The filename
  ///
  String baseName = '';

  /// The flag indicating the entity is actually a directory link
  ///
  bool isLink = false;

  /// The entity path
  ///
  String path = '';

  /// The entity path (POSIX-compliant)
  ///
  String posixPath = '';

  /// ./ or .\\ or empty
  ///
  String _shortCurDirName = '';

  /// The length of _shortCurDirName
  ///
  int _shortCurDirNameLen = 0;

  /// The file system
  ///
  final FileSystem fileSystem;

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
  FileListItem(this.fileSystem, {bool isTrimCurDirName = false}) {
    if (isTrimCurDirName) {
      _shortCurDirName = PathExt.shortCurDirName + fileSystem.path.separator;
      _shortCurDirNameLen = _shortCurDirName.length;
    }
  }

  /// The deep copy
  ///
  void copyFrom(FileListItem? rhs) {
    if (rhs == null) {
      return;
    }

    baseName = rhs.baseName;
    isLink = rhs.isLink;
    path = rhs.path;
    posixPath = rhs.posixPath;
    source = rhs.source;
    stat = rhs.stat;
    type = rhs.type;
  }

  /// Fetch the entity details (async)
  ///
  Future fetch(FileSystemEntity entity, bool isFollowLinks) async =>
      _fetch(entity, isFollowLinks, await entity.stat());

  /// Fetch the entity details (sync)
  ///
  void fetchSync(FileSystemEntity entity, bool isFollowLinks) =>
      _fetch(entity, isFollowLinks, entity.statSync());

  /// Fetch the entity details (common)
  ///
  void _fetch(FileSystemEntity entity, bool isFollowLinks, FileStat stat) {
    baseName = entity.basename;
    path = entity.path;
    posixPath = fileSystem.path.toPosix(path);
    source = entity;
    this.stat = stat;
    type = stat.type;
    isLink = (isFollowLinks ? false : (entity is Link));

    if ((_shortCurDirNameLen > 0) && path.startsWith(_shortCurDirName)) {
      path = path.substring(_shortCurDirNameLen);
    }
  }
}

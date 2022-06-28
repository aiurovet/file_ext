// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file_ext/file_ext.dart';

/// A helper extension for the FileSystem API
///
extension FileSystemExt on FileSystem {
  /// Const: local filesystem object
  ///
  static final local = LocalFileSystem();

  /// A wrapper for `FileList(...).exec(...)`, asynchronous (non-blocking)
  ///
  Future<List<String>> list(
          {String? root,
          List<String>? roots,
          FileFilter? filter,
          FileFilterList? filterList,
          FileFilterLists? filterLists,
          FileSystemEntityType? type,
          List<FileSystemEntityType>? types,
          int flags = FileList.followLinks,
          FileListHandler? listHandler,
          FileListHandlerSync? listHandlerSync,
          FileListErrorHandler? errorHandler}) async =>
      await FileList(this,
              root: root,
              roots: roots,
              filter: filter,
              filterList: filterList,
              filterLists: filterLists,
              type: type,
              types: types,
              flags: flags,
              listHandler: listHandler,
              listHandlerSync: listHandlerSync,
              errorHandler: errorHandler)
          .fetch();

  /// A wrapper for `FileList(...).execSync(...)`, synchronous (blocking)
  ///
  List<String> listSync(
          {String? root,
          List<String>? roots,
          FileFilter? filter,
          FileFilterList? filterList,
          FileFilterLists? filterLists,
          FileSystemEntityType? type,
          List<FileSystemEntityType>? types,
          int flags = FileList.followLinks,
          FileListHandlerSync? listHandlerSync,
          FileListErrorHandler? errorHandler}) =>
      FileList(this,
              root: root,
              roots: roots,
              filter: filter,
              filterList: filterList,
              filterLists: filterLists,
              type: type,
              types: types,
              flags: flags,
              listHandlerSync: listHandlerSync,
              errorHandler: errorHandler)
          .fetchSync();
}

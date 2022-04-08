// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/src/file_list_options.dart';
import 'package:file_ext/src/file_list_proc.dart';
import 'package:file_ext/src/path_ext.dart';

/// A helper extension for the FileSystem API
///
extension FileSystemExt on FileSystem {
  /// Retrieve the list of filesystem entities based on the filesystem [fs] and
  /// the glob pattern string [pattern], optionally, allowing hidden files,
  /// following links and executing user-defined functions (sync or async)
  ///
  /// Non-blocking mode
  ///
  Future<List<FileSystemEntity>> list(
      {String? root,
      List<String>? patterns,
      bool allowHidden = false,
      FileListProc? filterProc,
      FileListProcSync? filterProcSync,
      bool followLinks = true}) async {
    // Create the options object parsing all patterns in the list
    //
    var options = FileListOptions(this, root: root, patterns: patterns);

    // Get the list of all filesystem entities as stream
    //
    var entities = directory(options.root)
        .list(recursive: options.recursive, followLinks: followLinks);

    // Loop through the list of all filesystem entities and filter those accumulating the result
    //
    var result = <FileSystemEntity>[];

    await for (var entity in entities) {
      if (!allowHidden && path.isHidden(entity.path)) {
        continue;
      }

      var entityPath = entity.path;
      var entityName = path.basename(entityPath);
      var matches = true;

      for (var filter in options.filters) {
        if (!filter.matches(entityPath, entityName)) {
          matches = false;
          break;
        }
      }

      if (!matches) {
        continue;
      }

      if (filterProc != null) {
        if (!await filterProc(entity, entityPath, entityName, options)) {
          continue;
        }
      }

      if (filterProcSync != null) {
        if (!filterProcSync(entity, entityPath, entityName, options)) {
          continue;
        }
      }

      result.add(entity);
    }

    // Return the result
    //
    return result;
  }

  /// Retrieve the list of filesystem entities based on the filesystem [fs] and
  /// the glob pattern string [take], optionally, allowing hidden files,
  /// following links and executing a user-defined function
  ///
  /// Synchronous (blocking) mode
  ///
  List<FileSystemEntity> listSync(
      {String? root,
      List<String>? patterns,
      bool allowHidden = false,
      FileListProcSync? filterProcSync,
      bool followLinks = true}) {
    // Create the options object parsing all patterns in the list
    //
    var options = FileListOptions(this, root: root, patterns: patterns);

    // Get the list of all filesystem entities as stream
    //
    var entities = directory(options.root)
        .listSync(recursive: options.recursive, followLinks: followLinks);

    // Loop through the list of all filesystem entities and filter those accumulating the result
    //
    var result = <FileSystemEntity>[];

    for (var entity in entities) {
      if (!allowHidden && path.isHidden(entity.path)) {
        continue;
      }

      var entityPath = entity.path;
      var entityName = path.basename(entityPath);
      var hasMatch = true;

      for (var filter in options.filters) {
        if (!filter.matches(entityPath, entityName)) {
          hasMatch = false;
          break;
        }
      }

      if (!hasMatch) {
        continue;
      }

      if (filterProcSync != null) {
        if (!filterProcSync(entity, entityPath, entityName, options)) {
          continue;
        }
      }

      result.add(entity);
    }

    // Return the result
    //
    return result;
  }
}

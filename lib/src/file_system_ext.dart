// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';

/// A helper extension for the FileSystem API
///
extension FileSystemExt on FileSystem {
  /// Retrieve the list of filesystem entities based on the filesystem [fs],
  /// comma-separated list string [root] and the FileFilter pattern string
  /// [pattern], optionally, allowing hidden files, following links and
  /// executing user-defined functions (sync or async)
  ///
  /// Asynchronous (non-blocking) mode
  ///
  Future<List<String>> list(
      {String? root,
      List<String>? roots,
      String? pattern,
      List<String>? patterns,
      bool accumulate = true,
      bool allowHidden = false,
      FileSystemEntityType? type,
      List<FileSystemEntityType>? types,
      FileListProc? filterProc,
      FileListProcSync? filterProcSync,
      FileListErrorProc? errorProc,
      bool followLinks = true}) async {
    // The resulting list
    //
    var result = <String>[];

    // Create the options object parsing all patterns in the list
    //
    var options = FileListOptions(this,
        root: root,
        roots: roots,
        pattern: pattern,
        patterns: patterns,
        type: type,
        types: types,
        accumulate: accumulate,
        allowHidden: allowHidden,
        filterProc: filterProc,
        filterProcSync: filterProcSync);

    // Accumulate filtered entities
    //
    for (final root in options.roots) {
      await _list(result, root, options, followLinks: followLinks);
    }

    return result;
  }

  /// Retrieve the list of filesystem entities based on the filesystem [fs],
  /// comma-separated list string [root] and the FileFilter pattern string
  /// [pattern], optionally, allowing hidden files, following links and
  /// executing user-defined functions (sync or async)
  ///
  /// Synchronous (blocking) mode
  ///
  List<String> listSync(
      {String? root,
      List<String>? roots,
      String? pattern,
      List<String>? patterns,
      bool accumulate = true,
      bool allowHidden = false,
      FileSystemEntityType? type,
      List<FileSystemEntityType>? types,
      FileListProc? filterProc,
      FileListProcSync? filterProcSync,
      FileListErrorProc? errorProc,
      bool followLinks = true}) {
    // The resulting list
    //
    var result = <String>[];

    // Create the options object parsing all patterns in the list
    //
    var options = FileListOptions(this,
        root: root,
        roots: roots,
        pattern: pattern,
        patterns: patterns,
        type: type,
        types: types,
        accumulate: accumulate,
        allowHidden: allowHidden,
        filterProc: filterProc,
        filterProcSync: filterProcSync);

    // Accumulate filtered entities
    //
    for (final root in options.roots) {
      _listSync(result, root, options, followLinks: followLinks);
    }

    return result;
  }

  /// The essential part of `list(...)`: does everything after the [options]
  /// object created and the next root taken
  ///
  Future<List<String>> _list(
      List<String> result, String root, FileListOptions options,
      {bool followLinks = true}) async {
    // Retrieve all entites in this directory and don't catch any exception here
    //
    final entities = await directory(root)
        .list(recursive: false, followLinks: followLinks)
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final paths = <String>[];

    for (final entity in entities) {
      try {
        final matchedPath = await options.getMatchedPath(entity);

        if (matchedPath.isNotEmpty) {
          paths.add(matchedPath);
        }
      } on Error catch (e, stackTrace) {
        if (options.errorProc != null) {
          options.errorProc!(e, stackTrace);
        }
      } on Exception catch (e, stackTrace) {
        if (options.errorProc != null) {
          options.errorProc!(e, stackTrace);
        }
      }
    }

    // Make the access faster
    //
    final accumulate = options.accumulate;
    final sep = path.separator;

    // Add the list of paths under the current root to the result
    // (no sub-directories yet)
    //
    if (accumulate) {
      result.addAll(paths);
    }

    // In case of recursion, call this method again in the loop for each
    // sub-directory
    //
    if (options.recursive) {
      for (var i = 0, n = result.length; i < n; i++) {
        final path = result[i];

        if (path.endsWith(sep)) {
          await _list(result, path, options, followLinks: followLinks);
        }
      }
    }

    // Return result
    //
    return result;
  }

  /// The essential part of `listSync(...)`: does everything after the
  /// [options] object created. This separation is needed for recursion
  /// which does require the [options] re-creation
  ///
  List<String> _listSync(
      List<String> result, String root, FileListOptions options,
      {bool followLinks = true}) {
    // Retrieve all entites in this directory and don't catch any exception here
    //
    final entities = directory(root)
        .listSync(recursive: false, followLinks: followLinks)
      ..sort((a, b) => a.path.compareTo(b.path));

    final paths = <String>[];

    for (final entity in entities) {
      try {
        final matchedPath = options.getMatchedPathSync(entity);

        if (matchedPath.isNotEmpty) {
          paths.add(matchedPath);
        }
      } on Error catch (e, stackTrace) {
        if (options.errorProc != null) {
          options.errorProc!(e, stackTrace);
        }
      } on Exception catch (e, stackTrace) {
        if (options.errorProc != null) {
          options.errorProc!(e, stackTrace);
        }
      }
    }

    // Make the access faster
    //
    final accumulate = options.accumulate;
    final sep = path.separator;

    // Add the list of paths under the current root to the result
    // (no sub-directories yet)
    //
    if (accumulate) {
      result.addAll(paths);
    }

    // In case of recursion, call this method again in the loop for each
    // sub-directory
    //
    if (options.recursive) {
      for (var i = 0, n = result.length; i < n; i++) {
        final path = result[i];

        if (path.endsWith(sep)) {
          _listSync(result, path, options, followLinks: followLinks);
        }
      }
    }

    // Return result
    //
    return result;
  }
}

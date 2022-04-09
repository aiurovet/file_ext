// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/src/file_list_options.dart';

/// An error handler accepting either Error or Exception object
/// as the first argument
///
typedef FileListErrorProc = void Function(Object, StackTrace);

/// A type for async callback function used by `FileSystemExt.list(...)`\
/// or `FileSystemExt.listSync(...)` for every found entity\
/// \
/// Passes the path, basename, FileStat object and
/// filtering options\
/// Returns true/false to take/skip the entity
///
typedef FileListProc = Future<bool> Function(
    String, String, FileStat stat, FileListOptions);

/// A type for sync callback function used by `FileSystemExt.listSync(...)`
/// for every found entity\
/// \
/// Passes the current filesystem entity, its path, basename and
/// filtering options\
/// Returns true/false to take/skip the entity
///
typedef FileListProcSync = bool Function(
    String, String, FileStat stat, FileListOptions);

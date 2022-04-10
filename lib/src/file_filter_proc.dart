// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/src/file_list.dart';

/// An error handler accepting either Error or Exception object
/// as the first argument\
/// Returns true to continue or false to rethrow
///
typedef FileFilterErrorProc = bool Function(Object, StackTrace);

/// A type for async callback function used by `FileSystemExt.list(...)`\
/// or `FileSystemExt.listSync(...)` for every found entity\
/// \
/// Passes the current filesystem entity's path, basename,
/// filestat and all filtering options\
/// Returns true/false to take/skip the entity
///
typedef FileFilterProc = Future<bool> Function(
    String, String, FileStat stat, FileList);

/// A type for sync callback function used by `FileSystemExt.listSync(...)`
/// for every found entity\
/// \
/// Passes the current filesystem entity's path, basename,
/// filestat and all filtering options\
/// Returns true/false to take/skip the entity
///
typedef FileFilterProcSync = bool Function(
    String, String, FileStat stat, FileList);

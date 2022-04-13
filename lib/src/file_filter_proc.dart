// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/src/file_list.dart';

/// A user-defined error handler\
/// \
/// Returns true to continue or false to rethrow
///
typedef FileFilterErrorProc = bool Function(
    Object errorOrException, StackTrace stackTrace);

/// A type for async callback function used by `FileSystemExt.list(...)`\
/// or `FileSystemExt.listSync(...)` for every found filesystem entity\
/// \
/// Returns true/false to take/skip the entity
///
typedef FileFilterProc = Future<bool> Function(
    FileList sender, String path, String baseName, FileStat stat);

/// A type for sync callback function used by `FileSystemExt.listSync(...)`
/// for every found filesystem entity\
/// \
/// Returns true/false to take/skip the entity
///
typedef FileFilterProcSync = bool Function(
    FileList sender, String path, String baseName, FileStat stat);

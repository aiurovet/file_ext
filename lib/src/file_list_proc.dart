// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/src/file_list_options.dart';

/// A type for async callback function used by `FileSystemExt.list(...)`\
/// or `FileSystemExt.listSync(...)` for every found entity\
/// \
/// Passes the current filesystem entity, its path, basename and filtering options\
/// Returns true/false to continue/stop
///
typedef FileListProc = Future<bool> Function(
    FileSystemEntity, String, String, FileListOptions);

/// A type for sync callback function used by `FileSystemExt.listSync(...)`
/// for every found entity\
/// \
/// Passes the current filesystem entity, its path, basename and filtering options\
/// Returns true/false to continue/stop
///
typedef FileListProcSync = bool Function(
    FileSystemEntity, String, String, FileListOptions);

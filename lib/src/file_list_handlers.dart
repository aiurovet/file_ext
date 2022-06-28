// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/src/file_list.dart';
import 'package:file_ext/src/file_list_item.dart';
import 'package:file_ext/src/file_list_error_info.dart';

/// A user-defined error handler\
/// \
/// Returns true to continue or false to rethrow
///
typedef FileListErrorHandler = bool Function(
    FileList? sender, FileListErrorInfo item);

/// A type for async callback function used by `FileSystemExt.list(...)`\
/// or `FileSystemExt.listSync(...)` for every found filesystem entity\
/// \
/// Returns true/false to add/skip the entity
///
typedef FileListHandler = Future<bool> Function(
    FileList sender, FileListItem item);

/// A type for sync callback function used by `FileSystemExt.listSync(...)`
/// for every found filesystem entity\
/// \
/// Returns true/false to add/skip the entity
///
typedef FileListHandlerSync = bool Function(FileList sender, FileListItem item);

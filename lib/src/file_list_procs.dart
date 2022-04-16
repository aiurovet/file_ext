// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/src/file_list.dart';
import 'package:file_ext/src/file_list_entity_event_args.dart';
import 'package:file_ext/src/file_list_error_event_args.dart';

/// A user-defined error handler\
/// \
/// Returns true to continue or false to rethrow
///
typedef FileListErrorProc = bool Function(
    FileList? sender, FileListErrorEventArgs args);

/// A type for async callback function used by `FileSystemExt.list(...)`\
/// or `FileSystemExt.listSync(...)` for every found filesystem entity\
/// \
/// Returns true/false to add/skip the entity
///
typedef FileListProc = Future<bool> Function(
    FileList sender, FileListEntityEventArgs args);

/// A type for sync callback function used by `FileSystemExt.listSync(...)`
/// for every found filesystem entity\
/// \
/// Returns true/false to add/skip the entity
///
typedef FileListProcSync = bool Function(
    FileList sender, FileListEntityEventArgs args);

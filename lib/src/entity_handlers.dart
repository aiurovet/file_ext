// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';

/// A user-defined error handler (non-blocking)\
/// \
/// Returns true to continue the loop or false to rethrow
///
typedef FileSystemEntityExceptionHandler = Future<bool> Function(
    FileSystem fileSystem, FileSystemEntity? entity, FileStat? stat, Exception exception, StackTrace stackTrace);

/// A user-defined error handler (blocking)\
/// \
/// Returns true to continue the loop or false to rethrow
///
typedef FileSystemEntityExceptionHandlerSync = bool Function(
    FileSystem fileSystem, FileSystemEntity? entity, FileStat? stat, Exception exception, StackTrace stackTrace);

/// A type for async callback function used by `FileSystemExt.list(...)`\
/// or `FileSystemExt.listSync(...)` for every found filesystem entity\
/// \
/// Returns true to continue the loop or false to stop
///
typedef FileSystemEntityHandler = Future<bool> Function(
    FileSystem fileSystem, FileSystemEntity? entity, FileStat? stat);

/// A type for sync callback function used by `FileSystemExt.listSync(...)`
/// for every found filesystem entity\
/// \
/// Returns true to continue the loop or false to stop
///
typedef FileSystemEntityHandlerSync = bool Function(
    FileSystem fileSystem, FileSystemEntity? entity, FileStat? stat);

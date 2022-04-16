// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/src/file_list_entity_event_args.dart';

/// The details of an error event
///
class FileListErrorEventArgs extends FileListEntityEventArgs {
  /// Error object in case of Error or null
  ///
  final Error? error;

  /// Exception object in case of Exception or null
  ///
  final Exception? exception;

  /// The stack trace
  ///
  final StackTrace? stackTrace;

  /// The constructor populating all properties
  ///
  FileListErrorEventArgs(
      {FileListEntityEventArgs? entityArgs,
      this.error,
      this.exception,
      this.stackTrace}) {
    copyFrom(entityArgs);
  }
}

// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/src/file_list_item.dart';

/// The details of an error event
///
class FileListErrorInfo {
  /// Error object in case of Error or null
  ///
  final Error? error;

  /// Exception object in case of Exception or null
  ///
  final Exception? exception;

  /// The stack trace
  ///
  final FileListItem? item;

  /// The stack trace
  ///
  final StackTrace? stackTrace;

  /// The constructor populating all properties
  ///
  FileListErrorInfo({this.error, this.exception, this.item, this.stackTrace});
}

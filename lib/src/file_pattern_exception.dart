// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

/// Exception base for FilePattern-related issues
///
class FilePatternException implements Exception {
  /// Free text explaining what is this exception about
  ///
  String get description => _description;
  late final String _description;

  /// Default constructor
  ///
  FilePatternException([String? description]) {
    _description = description ?? '';
  }

  /// An override of the default toString() showing explanation and data
  ///
  @override
  String toString() => description;
}

/// Exception base for FilePattern-related issues
///
class BadSeparatorFilePatternException extends FilePatternException {
  /// Default constructor
  ///
  BadSeparatorFilePatternException([String? description]) :
    super('Path separator cannot be part of a character group');
  
  /// An override of the default toString() showing explanation and data
  ///
  @override
  String toString() => description;
}

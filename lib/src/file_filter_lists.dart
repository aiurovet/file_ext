// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';

/// Type for the collection of distinct or-filtersets
///
typedef FileFilterLists = List<List<FileFilter>>;

/// Extension methods for [FileFilterLists]
///
extension FileFilterListsExt on FileFilterLists {
  /// Check whether the new filter differs from the existing ones
  ///
  bool containsSimilarElement(FileFilterList newFilterList) {
    for (var filters in this) {
      if (filters.isSimilarTo(newFilterList)) {
        return true;
      }
    }
    return false;
  }

  /// Add new filter with the pattern different to any of the existing ones
  ///
  void addNew(FileFilterList newFilterList) {
    if (!containsSimilarElement(newFilterList)) {
      add(newFilterList);
    }
  }

  /// Add new range of filters with the pattern different to any of the existing ones
  ///
  void addAllNew(Iterable<FileFilterList> newFilterLists) {
    for (var newFilterList in newFilterLists) {
      addNew(newFilterList);
    }
  }
}

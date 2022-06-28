// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';

/// Type for the collection of distinct and-filters
///
typedef FileFilterList = List<FileFilter>;

/// Extension methods for [FileFilterList]
///
extension FileFilterListExt on FileFilterList {
  /// Check whether the new filter differs from the existing ones
  ///
  bool containsSimilarElement(FileFilter newFilter) {
    return (indexWhere((x) => (x.isRegular
            ? x.pattern == newFilter.pattern
            : x.fileSystem.path.equals(x.pattern, newFilter.pattern))) >=
        0);
  }

  /// Check whether the new filter list has all elements similar to the existing ones
  ///
  bool isSimilarTo(Iterable<FileFilter> newFilterList) {
    for (var newFilter in newFilterList) {
      if (containsSimilarElement(newFilter)) {
        return true;
      }
    }
    return false;
  }

  /// Add new filter with the pattern different to any of the existing ones
  ///
  void addNew(FileFilter newFilter) {
    if (!containsSimilarElement(newFilter)) {
      add(newFilter);
    }
  }

  /// Add new range of filters with the pattern different to any of the existing ones
  ///
  void addAllNew(Iterable<FileFilter> newFilters) {
    for (var newFilter in newFilters) {
      if (!containsSimilarElement(newFilter)) {
        add(newFilter);
      }
    }
  }

  /// Ensure the first filter is positive glob
  ///
  void normalize(FileSystem fileSystem) {
    if (isEmpty) {
      add(FileFilter.any(fileSystem));
      return;
    }

    final first = this.first;

    if (!first.isRegular && !first.isNegative) {
      return;
    }

    var found = firstWhereOrNull((x) => !x.isRegular && !x.isNegative);

    if (found == null) {
      found = FileFilter(fileSystem,
          PathExt.anyPattern(where((x) => x.isRecursive).isNotEmpty));
    } else {
      remove(found);
    }

    insert(0, found);
  }

  /// FileFilter finder
  ///
  FileFilter? firstWhereOrNull(bool Function(FileFilter filter) test) {
    for (var filter in this) {
      if (test(filter)) {
        return filter;
      }
    }
    return null;
  }
}

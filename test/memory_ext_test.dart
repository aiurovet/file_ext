// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for MemoryFileSystemExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final styleName = fs.getStyleName();

    group('PathExt - $styleName -', () {
      test('styleName', () {
        expect(styleName, fs.path.isPosix ? 'Posix' : 'Windows');
      });
    });
  });
  test('PathExt - forEach', () {
    var styleNames = <String>[];

    MemoryFileSystemExt.forEach((mfs) {
      styleNames.add(mfs.getStyleName());
    });

    expect(styleNames, ['Posix', 'Windows']);
  });
}

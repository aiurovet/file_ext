// Copyright (c) 2022-2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for MemoryFileSystemExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final styleName = fs.getStyleName();

    group('MemoryFileSystemExt - $styleName -', () {
      test('getStyleName', () {
        expect(fs.getStyleName(), fs.path.isPosix ? 'posix' : 'windows');
      });
    });
  });
  test('MemoryFileSystemExt - forEach', () {
    var styleNames = <String>[];

    MemoryFileSystemExt.forEach((mfs) {
      styleNames.add(mfs.getStyleName());
    });

    expect(styleNames, ['posix', 'windows']);
  });
}

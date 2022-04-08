// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for MemoryFileSystemExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    var fsp = fs.path;

    group('PathExt - ${fs.styleName} -', () {
      test('styleName', () {
        expect(fs.styleName, fsp.isPosix ? 'POSIX' : 'Windows');
      });
      test('forEach', () {
        var styleNames = <String>[];

        MemoryFileSystemExt.forEach((fs) {
          styleNames.add(fs.styleName);
        });

        expect(styleNames.length, 2);
        expect(styleNames.contains('POSIX'), true);
        expect(styleNames.contains('Windows'), true);
      });
    });
  });
}

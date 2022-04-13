// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/src/memory_ext.dart';
import 'package:file_ext/src/path_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for PathExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final fsp = fs.path;
    final sep = fsp.separator;

    group('PathExt - ${fs.styleName} -', () {
      test('adjust - null', () {
        expect(fsp.adjust(null), '');
      });
      test('adjust - empty', () {
        expect(fsp.adjust(''), '');
      });
      test('adjust - mix', () {
        expect(fsp.adjust(r'\a\bc/def'), '\\a\\bc${sep}def');
      });
    });
  });
}

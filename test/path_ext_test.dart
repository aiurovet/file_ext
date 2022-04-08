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
      test('getFullPath - empty', () {
        expect(fsp.equals(fsp.getFullPath(''), fsp.current), true);
      });
      test('getFullPath - current dir', () {
        expect(fsp.equals(fsp.getFullPath('.'), fsp.current), true);
      });
      test('getFullPath - parent dir', () {
        final full = fsp.getFullPath('..');
        expect(fsp.equals(full, fsp.dirname(fsp.current)), true);
      });
      test('getFullPath - parent/other', () {
        final full = fsp.getFullPath('..${sep}a${sep}bc');
        final dirName = fsp.dirname(fsp.current);
        expect(fsp.equals(full, '$dirName${sep}a${sep}bc'), true);
      });
      test('getFullPath - absolute', () {
        final full = fsp.getFullPath('${sep}a${sep}bc');
        expect(fsp.equals(full, '${sep}a${sep}bc'), true);
      });
      test('getFullPath - file in the root dir', () {
        final full = fsp.getFullPath('${sep}Abc.txt');
        expect(fsp.equals(full, r'Abc.txt'), true);
      });
      test('getFullPath - unicode characters', () {
        final orig = '$sepСаша.Текст';
        final full = fsp.getFullPath(orig);
        expect(fsp.equals(full, orig), true);
      });
    });
  });
}

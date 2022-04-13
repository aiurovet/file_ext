// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for FileSystemExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final fsp = fs.path;
    final sep = fsp.separator;
    final top = 'dir';
    final sub1 = fsp.join(top, 'sub1');
    final sub2 = fsp.join(sub1, 'sub2');

    group('FileSystemExt - ${fs.styleName} -', () {
      // Future setup() async {
      //   await fs.directory(sub2).create(recursive: true);

      //   await fs.file(fsp.join(top, 'file11.doc')).create();
      //   await fs.file(fsp.join(top, 'file12.txt')).create();

      //   await fs.file(fsp.join(sub1, 'file21.doc')).create();
      //   await fs.file(fsp.join(sub1, 'file22.txt')).create();

      //   await fs.file(fsp.join(sub2, 'file31.doc')).create();
      //   await fs.file(fsp.join(sub2, 'file32.txt')).create();
      // }

      test('getFullPath - empty', () {
        expect(fsp.equals(fs.getFullPath(''), fsp.current), true);
      });
      test('getFullPath - current dir', () {
        expect(fsp.equals(fs.getFullPath('.'), fsp.current), true);
      });
      test('getFullPath - parent dir', () {
        final full = fs.getFullPath('..');
        expect(fsp.equals(full, fsp.dirname(fsp.current)), true);
      });
      test('getFullPath - parent/other', () {
        final full = fs.getFullPath('a$sep..$sep..$sep..${sep}bc');
        final dirName = fsp.dirname(fsp.current);
        expect(fsp.equals(full, '$dirName${sep}bc'), true);
      });
      test('getFullPath - absolute', () {
        final full = fs.getFullPath('${sep}a${sep}bc');
        expect(fsp.equals(full, '${sep}a${sep}bc'), true);
      });
      test('getFullPath - absolute with double sep', () {
        final full = fs.getFullPath('$sep${sep}a$sep.$sep${sep}bc');
        expect(fsp.equals(full, '${sep}a${sep}bc'), true);
      });
      test('getFullPath - file in the root dir', () {
        final full = fs.getFullPath('${sep}Abc.txt');
        expect(fsp.equals(full, '${sep}Abc.txt'), true);
      });
      test('getFullPath - a mix of separators', () {
        final full = fs.getFullPath(r'/A\b/C\d');
        expect(
            fsp.equals(full, (fsp.isPosix ? r'/A\b/C\d' : r'\A\b\C\d')), true);
      });
      test('getFullPath - unicode characters', () {
        final orig = '$sepСаша.Текст';
        final full = fs.getFullPath(orig);
        expect(fsp.equals(full, orig), true);
      });
      // test('list - top', () async {
      //   await setup();
      //   var flst = await fs.list(root: top, patterns: ['*.txt']);
      //   expect(flst.length, 1);
      // });
      // test('listSync', () async {
      //   await setup();
      // });
    });
  });
}

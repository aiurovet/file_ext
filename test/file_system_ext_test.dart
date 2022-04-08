// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for FileSystemExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final fsp = fs.path;
    final top = 'dir';
    final sub1 = fsp.join(top, 'sub1');
    final sub2 = fsp.join(sub1, 'sub2');

    group('FileSystemExt - ${fs.styleName} -', () {
      Future setup() async {
        await fs.directory(sub2).create(recursive: true);

        await fs.file(fsp.join(top, 'file11.doc')).create();
        await fs.file(fsp.join(top, 'file12.txt')).create();

        await fs.file(fsp.join(sub1, 'file21.doc')).create();
        await fs.file(fsp.join(sub1, 'file22.txt')).create();

        await fs.file(fsp.join(sub2, 'file31.doc')).create();
        await fs.file(fsp.join(sub2, 'file32.txt')).create();
      }

      test('list - top', () async {
        await setup();
        var flst = await fs.list(root: top, patterns: ['*.txt']);
        expect(flst.length, 1);
      });
      test('listSync', () async {
        await setup();
      });
    });
  });
}

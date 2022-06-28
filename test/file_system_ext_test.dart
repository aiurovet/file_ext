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
      setUp(() async {
        await fs.directory(sub2).create(recursive: true);

        await fs.file(fsp.join(top, 'file11.doc')).create();
        await fs.file(fsp.join(top, 'file12.txt')).create();
        await fs.file(fsp.join(top, 'file13.docx')).create();

        await fs.file(fsp.join(sub1, 'file21.doc')).create();
        await fs.file(fsp.join(sub1, 'file22.txt')).create();
        await fs.file(fsp.join(sub1, 'file23.docx')).create();

        await fs.file(fsp.join(sub2, 'file31.doc')).create();
        await fs.file(fsp.join(sub2, 'file32.txt')).create();
        await fs.file(fsp.join(sub1, 'file33.docx')).create();
      });

      // test('list - top', () async {
      //   var flst = await fs.list(root: top, patterns: [
      //     FileFilter('*.doc*'),
      //     FileFilter('*.tx*'),
      //     FileFilter('*.docx', isNegative: true),
      //   ]);
      //   expect(flst.length, 2);
      // });
      // test('listSync - top', () async {
      //   var flst = fs.listSync(root: top, patterns: [
      //     FileFilter('*.doc*'),
      //     FileFilter('*.tx*'),
      //     FileFilter('*.docx', isNegative: true)
      //   ]);
      //   expect(flst.length, 2);
      // });
    });
  });
}

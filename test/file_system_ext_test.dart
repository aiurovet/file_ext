// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

/// A suite of tests for FileSystemExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final top = 'dir';
    final sub1 = fs.path.join(top, 'sub1');
    final sub2 = fs.path.join(sub1, 'sub2');

    group('FileSystemExt - ${fs.getStyleName()} -', () {
      setUp(() async {
        await fs.directory(sub2).create(recursive: true);

        await fs.file(fs.path.join(top, 'file11.doc')).create();
        await fs.file(fs.path.join(top, 'file12.txt')).create();
        await fs.file(fs.path.join(top, 'file13.docx')).create();

        await fs.file(fs.path.join(sub1, 'file21.doc')).create();
        await fs.file(fs.path.join(sub1, 'file22.txt')).create();
        await fs.file(fs.path.join(sub1, 'file23.docx')).create();

        await fs.file(fs.path.join(sub2, 'file31.doc')).create();
        await fs.file(fs.path.join(sub2, 'file32.txt')).create();
        await fs.file(fs.path.join(sub1, 'file33.docx')).create();
      });

      test('forEachEntity - top', () async {
        var flst = await fs.forEachEntity(
            root: top,
            filter: Glob('*.{doc*,tx*,docx}'),
            flags: FileSystemExt.accumulate);
        expect(flst.length, 3);
      });
      test('forEachEntitySync - top', () async {
        var flst = fs.forEachEntitySync(
            root: top,
            filter: Glob('*.{doc*,tx*,docx}'),
            flags: FileSystemExt.accumulate);
        expect(flst.length, 3);
      });
    });
  });
}

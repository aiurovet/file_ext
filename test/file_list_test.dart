// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for PathExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final fsp = fs.path;

    final top1 = 'dir1';
    final top2 = 'dir2';

    final sub1 = fsp.join(top1, 'sub1');
    final sub12 = fsp.join(sub1, 'sub2');

    final sub2 = fsp.join(top2, 'sub2');
    final sub21 = fsp.join(sub2, 'sub1');
    final sub22 = fsp.join(sub2, 'sub2');

    final roots = <String>[];

    final pat = <FileFilter>[
      FileFilter('$top1/*.doc'),
      FileFilter('$sub22/**.{txt,lst} and not \\/file[13][12]')
    ];

    FileList? fl;

    setUp(() async {
      await fs.directory(sub1).create(recursive: true);
      await fs.directory(sub12).create(recursive: true);
      await fs.directory(sub21).create(recursive: true);
      await fs.directory(sub22).create(recursive: true);

      await fs.file(fsp.join(top1, 'file01.doc')).create();
      await fs.file(fsp.join(top2, 'file02.txt')).create();

      await fs.file(fsp.join(sub1, 'file11.doc')).create();
      await fs.file(fsp.join(sub12, 'file12.lst')).create();

      await fs.file(fsp.join(sub21, 'file21.doc')).create();
      await fs.file(fsp.join(sub22, 'file22.txt')).create();

      fl = FileList(fs, roots: roots, patterns: pat);
    });

    group('FileList - ${fs.styleName} -', () {
      test('constructor', () async {
        expect(fl?.roots.toString(), '[]');
        expect(fl?.patterns.length, 2);
      });
      test('fetch from a single pattern', () async {
        var files = await FileList(fs, pattern: pat[0]).fetch();

        expect(files.isNotEmpty, true);
      });
    });
  });
}

// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_ext/src/memory_ext.dart';
import 'package:file_ext/src/path_ext.dart';
import 'package:test/test.dart';

var newTopDir = '';

/// Data setup
///
void setUpHandler(FileSystem fs) {
  newTopDir = fs.path.join('/sub1', 'sub2');
  fs.directory(newTopDir).createSync(recursive: true);
  fs.currentDirectory = newTopDir;
}

/// A suite of tests for PathExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final sep = fs.path.separator;
    final styleName = fs.getStyleName();

    group('PathExt - adjust - $styleName -', () {
      setUp(() => setUpHandler(fs));
      test('null', () {
        expect(fs.path.adjust(null), '');
      });
      test('empty', () {
        expect(fs.path.adjust(''), '');
      });
      test('mix', () {
        expect(fs.path.adjust(r'\a\bc/def'), r'\a\bc' + sep + r'def');
      });
    });
    group('PathExt - adjustTrailingSeparator - $styleName -', () {
      setUp(() => setUpHandler(fs));
      test('dir - empty - add', () {
        expect(
            fs.path.adjustTrailingSeparator('', FileSystemEntityType.directory,
                isAppend: true),
            r'');
      });
      test('dir - empty - remove', () {
        expect(
            fs.path.adjustTrailingSeparator('', FileSystemEntityType.directory,
                isAppend: true),
            r'');
      });
      test('dir - root - add', () {
        expect(
            fs.path.adjustTrailingSeparator(sep, FileSystemEntityType.directory,
                isAppend: true),
            sep);
      });
      test('dir - root - remove', () {
        expect(
            fs.path.adjustTrailingSeparator(sep, FileSystemEntityType.directory,
                isAppend: true),
            sep);
      });
      test('dir - drive (win) - add', () {
        if (fs.style == FileSystemStyle.windows) {
          expect(
              fs.path.adjustTrailingSeparator(r'c:', FileSystemEntityType.directory,
                  isAppend: true),
              r'c:.\');
        }
      });
      test('dir - drive (win) - remove', () {
        if (fs.style == FileSystemStyle.windows) {
          expect(
              fs.path.adjustTrailingSeparator(r'c:', FileSystemEntityType.directory,
                  isAppend: false),
              r'c:');
        }
      });
      test('dir - abc - add', () {
        expect(
            fs.path.adjustTrailingSeparator('abc', FileSystemEntityType.directory,
                isAppend: true),
            r'abc' + sep);
      });
      test('dir - abc - remove', () {
        expect(
            fs.path.adjustTrailingSeparator(
                'abc' + sep, FileSystemEntityType.directory,
                isAppend: false),
            r'abc');
      });
      test('dir - ab/c - add', () {
        expect(
            fs.path.adjustTrailingSeparator(
                'ab' + sep + 'c', FileSystemEntityType.directory,
                isAppend: true),
            r'ab' + sep + 'c' + sep);
      });
      test('dir - ab/c - remove', () {
        expect(
            fs.path.adjustTrailingSeparator(
                'ab' + sep + 'c', FileSystemEntityType.directory,
                isAppend: false),
            r'ab' + sep + 'c');
      });
      test('file - add', () {
        expect(
            fs.path.adjustTrailingSeparator(r'abc', FileSystemEntityType.file,
                isAppend: true),
            r'abc');
      });
      test('file - remove', () {
        expect(
            fs.path.adjustTrailingSeparator(r'abc' + sep, FileSystemEntityType.file,
                isAppend: false),
            r'abc' + sep);
      });
    });
    group('getFullPath - $styleName -', () {
      setUp(() => setUpHandler(fs));
      test('empty', () {
        expect(fs.path.equals(fs.path.getFullPath(''), fs.path.current), true);
      });
      test('current dir', () {
        expect(fs.path.equals(fs.path.getFullPath('.'), fs.path.current), true);
      });
      test('current sub-dir', () {
        expect(fs.path.equals(fs.path.getFullPath('x${sep}a.txt'), '${fs.path.current}${sep}x${sep}a.txt'), true);
      });
      test('parent dir', () {
        final full = fs.path.getFullPath('..');
        expect(fs.path.equals(full, fs.path.dirname(fs.path.current)), true);
      });
      test('root/other', () {
        final full = fs.path.getFullPath('a$sep..$sep..$sep..$sep..$sep..${sep}bc');
        expect(fs.path.equals(full, '${sep}bc'), true);
      });
      test('absolute', () {
        final full = fs.path.getFullPath('${sep}a${sep}bc');
        expect(fs.path.equals(full, '${sep}a${sep}bc'), true);
      });
      test('absolute with double sep', () {
        final full = fs.path.getFullPath('$sep${sep}a$sep.$sep${sep}bc');
        expect(fs.path.equals(full, '${sep}a${sep}bc'), fs.path.isPosix);
      });
      test('file in the root dir', () {
        final full = fs.path.getFullPath('${sep}Abc.txt');
        expect(fs.path.equals(full, '${sep}Abc.txt'), true);
      });
      test('getFullPath - a mix of separators', () {
        final full = fs.path.getFullPath(r'/A\b/C\d');
        expect(
            fs.path.equals(full, (fs.path.isPosix ? r'/A\b/C\d' : r'\A\b\C\d')), true);
      });
      test('getFullPath - unicode characters', () {
        final orig = '$sepСаша.Текст';
        final full = fs.path.getFullPath(orig);
        expect(fs.path.equals(full, orig), true);
      });
    });
    group('PathExt - glob - $styleName -', () {
      // setUp(() => setUpHandler(fs));
      // test('is recursive - abc/def.txt', () {
      //   expect(fs.path.isRecursivePattern('abc${sep}def.txt'), false);
      // });
      // test('is recursive - **.txt', () {
      //   expect(fs.path.isRecursivePattern('**.txt'), true);
      // });
      // test('is recursive - abc/*.txt', () {
      //   expect(fs.path.isRecursivePattern('abc$sep*.txt'), false);
      // });
      // test('is recursive - ab?c/*.txt', () {
      //   expect(fs.path.isRecursivePattern('ab?c$sep*.txt'), true);
      // });
    });
    group('PathExt - is hidden - $styleName -', () {
      setUp(() => setUpHandler(fs));
      test('empty', () {
        expect(fs.path.isHidden(''), false);
      });
      test('.', () {
        expect(fs.path.isHidden('.'), true);
      });
      test('abc.txt', () {
        expect(fs.path.isHidden('abc.txt'), false);
      });
      test('.abc.txt', () {
        expect(fs.path.isHidden('.abc.txt'), true);
      });
      test('./abc.txt', () {
        expect(fs.path.isHidden('.${sep}abc.txt'), false);
      });
      test('./../abc.txt', () {
        expect(fs.path.isHidden('.$sep..${sep}abc.txt'), false);
      });
      test('abc/def.txt', () {
        expect(fs.path.isHidden('abc${sep}def.txt'), false);
      });
      test('abc/.def.txt', () {
        expect(fs.path.isHidden('abc$sep.def.txt'), true);
      });
      test('abc\\.def.txt', () {
        expect(fs.path.isHidden(r'abc\.def.txt'), !fs.path.isPosix);
      });
    });
    group('PathExt - toPosix - $styleName -', () {
      setUp(() => setUpHandler(fs));
      test('null', () {
        expect(fs.path.toPosix(null), '');
      });
      test('empty', () {
        expect(fs.path.toPosix(''), '');
      });
      test('no separator', () {
        expect(fs.path.toPosix('abc.def'), 'abc.def');
      });
      test('general', () {
        expect(fs.path.toPosix(r'a\b/c.def'),
            'a' + (fs.path.isPosix ? r'\' : '/') + 'b/c.def');
      });
    });
  });
}

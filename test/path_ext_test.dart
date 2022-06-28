// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_ext/src/memory_ext.dart';
import 'package:file_ext/src/path_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for PathExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final fsp = fs.path;
    final sep = fsp.separator;

    group('PathExt - adjust - ${fs.styleName} -', () {
      test('null', () {
        expect(fsp.adjust(null), '');
      });
      test('empty', () {
        expect(fsp.adjust(''), '');
      });
      test('mix', () {
        expect(fsp.adjust(r'\a\bc/def'), r'\a\bc' + sep + r'def');
      });
    });
    group('PathExt - adjustEscaped - ${fs.styleName} -', () {
      test('null', () {
        expect(fsp.adjustEscaped(null), '');
      });
      test('empty', () {
        expect(fsp.adjustEscaped(''), '');
      });
      test('mix', () {
        expect(fsp.adjustEscaped(r'\\a\\bc/def'),
            r'\\a\\bc' + RegExp.escape(sep) + r'def');
      });
    });
    group('PathExt - adjustTrailingSeparator - ${fs.styleName} -', () {
      test('dir - empty - add', () {
        expect(
            fsp.adjustTrailingSeparator('', FileSystemEntityType.directory,
                isAppend: true),
            r'');
      });
      test('dir - empty - remove', () {
        expect(
            fsp.adjustTrailingSeparator('', FileSystemEntityType.directory,
                isAppend: true),
            r'');
      });
      test('dir - root - add', () {
        expect(
            fsp.adjustTrailingSeparator(sep, FileSystemEntityType.directory,
                isAppend: true),
            sep);
      });
      test('dir - root - remove', () {
        expect(
            fsp.adjustTrailingSeparator(sep, FileSystemEntityType.directory,
                isAppend: true),
            sep);
      });
      test('dir - drive (win) - add', () {
        if (fs.style == FileSystemStyle.windows) {
          expect(
              fsp.adjustTrailingSeparator(r'c:', FileSystemEntityType.directory,
                  isAppend: true),
              r'c:.\');
        }
      });
      test('dir - drive (win) - remove', () {
        if (fs.style == FileSystemStyle.windows) {
          expect(
              fsp.adjustTrailingSeparator(r'c:', FileSystemEntityType.directory,
                  isAppend: false),
              r'c:');
        }
      });
      test('dir - abc - add', () {
        expect(
            fsp.adjustTrailingSeparator('abc', FileSystemEntityType.directory,
                isAppend: true),
            r'abc' + sep);
      });
      test('dir - abc - remove', () {
        expect(
            fsp.adjustTrailingSeparator(
                'abc' + sep, FileSystemEntityType.directory,
                isAppend: false),
            r'abc');
      });
      test('dir - ab/c - add', () {
        expect(
            fsp.adjustTrailingSeparator(
                'ab' + sep + 'c', FileSystemEntityType.directory,
                isAppend: true),
            r'ab' + sep + 'c' + sep);
      });
      test('dir - ab/c - remove', () {
        expect(
            fsp.adjustTrailingSeparator(
                'ab' + sep + 'c', FileSystemEntityType.directory,
                isAppend: false),
            r'ab' + sep + 'c');
      });
      test('file - add', () {
        expect(
            fsp.adjustTrailingSeparator(r'abc', FileSystemEntityType.file,
                isAppend: true),
            r'abc');
      });
      test('file - remove', () {
        expect(
            fsp.adjustTrailingSeparator(r'abc' + sep, FileSystemEntityType.file,
                isAppend: false),
            r'abc' + sep);
      });
    });
    group('getFullPath - ', () {
      test('empty', () {
        expect(fsp.equals(fsp.getFullPath(''), fsp.current), true);
      });
      test('current dir', () {
        expect(fsp.equals(fsp.getFullPath('.'), fsp.current), true);
      });
      test('parent dir', () {
        final full = fsp.getFullPath('..');
        expect(fsp.equals(full, fsp.dirname(fsp.current)), true);
      });
      test('parent/other', () {
        final full = fsp.getFullPath('a$sep..$sep..$sep..${sep}bc');
        final dirName = fsp.dirname(fsp.current);
        expect(fsp.equals(full, '$dirName${sep}bc'), true);
      });
      test('absolute', () {
        final full = fsp.getFullPath('${sep}a${sep}bc');
        expect(fsp.equals(full, '${sep}a${sep}bc'), true);
      });
      test('absolute with double sep', () {
        final full = fsp.getFullPath('$sep${sep}a$sep.$sep${sep}bc');
        expect(fsp.equals(full, '${sep}a${sep}bc'), true);
      });
      test('file in the root dir', () {
        final full = fsp.getFullPath('${sep}Abc.txt');
        expect(fsp.equals(full, '${sep}Abc.txt'), true);
      });
      test('getFullPath - a mix of separators', () {
        final full = fsp.getFullPath(r'/A\b/C\d');
        expect(
            fsp.equals(full, (fsp.isPosix ? r'/A\b/C\d' : r'\A\b\C\d')), true);
      });
      test('getFullPath - unicode characters', () {
        final orig = '$sepСаша.Текст';
        final full = fsp.getFullPath(orig);
        expect(fsp.equals(full, orig), true);
      });
    });
    group('PathExt - glob - ${fs.styleName} -', () {
      // test('is recursive - abc/def.txt', () {
      //   expect(fsp.isRecursivePattern('abc${sep}def.txt'), false);
      // });
      // test('is recursive - **.txt', () {
      //   expect(fsp.isRecursivePattern('**.txt'), true);
      // });
      // test('is recursive - abc/*.txt', () {
      //   expect(fsp.isRecursivePattern('abc$sep*.txt'), false);
      // });
      // test('is recursive - ab?c/*.txt', () {
      //   expect(fsp.isRecursivePattern('ab?c$sep*.txt'), true);
      // });
    });
    group('PathExt - is hidden - ${fs.styleName} -', () {
      test('empty', () {
        expect(fsp.isHidden(''), false);
      });
      test('.', () {
        expect(fsp.isHidden('.'), true);
      });
      test('abc.txt', () {
        expect(fsp.isHidden('abc.txt'), false);
      });
      test('.abc.txt', () {
        expect(fsp.isHidden('.abc.txt'), true);
      });
      test('./abc.txt', () {
        expect(fsp.isHidden('.${sep}abc.txt'), false);
      });
      test('./../abc.txt', () {
        expect(fsp.isHidden('.$sep..${sep}abc.txt'), false);
      });
      test('abc/def.txt', () {
        expect(fsp.isHidden('abc${sep}def.txt'), false);
      });
      test('abc/.def.txt', () {
        expect(fsp.isHidden('abc$sep.def.txt'), true);
      });
      test('abc\\.def.txt', () {
        expect(fsp.isHidden(r'abc\.def.txt'), !fsp.isPosix);
      });
    });
    group('PathExt - is path/escaped - ${fs.styleName} -', () {
      test('null', () {
        expect(fsp.isPath(null), false);
      });
      test('empty', () {
        expect(fsp.isPath(null), false);
      });
      test('root', () {
        expect(fsp.isPath(sep), true);
      });
      test('anti-root', () {
        expect(fsp.isPath(sep == '/' ? '\\' : '/'), !fsp.isPosix);
      });
      test('contains drive', () {
        expect(fsp.isPath('c:'), !fsp.isPosix);
      });
      test('escaped - empty', () {
        expect(fsp.isPathEscaped(null), false);
      });
      test('escaped - root', () {
        expect(fsp.isPathEscaped(sep), fsp.isPosix);
      });
      test('escaped - alt-root', () {
        expect(fsp.isPathEscaped(sep == '/' ? '\\' : '/'), !fsp.isPosix);
      });
      test('escaped - contains drive', () {
        expect(fsp.isPathEscaped('c:'), !fsp.isPosix);
      });
    });
    group('PathExt - toPosix - ${fs.styleName} -', () {
      test('null', () {
        expect(fsp.toPosix(null), '');
      });
      test('empty', () {
        expect(fsp.toPosix(''), '');
      });
      test('no separator', () {
        expect(fsp.toPosix('abc.def'), 'abc.def');
      });
      test('general', () {
        expect(fsp.toPosix(r'a\b/c.def'),
            'a' + (fsp.isPosix ? r'\' : '/') + 'b/c.def');
      });
    });
    group('PathExt - toPosixEscaped - ${fs.styleName} -', () {
      test('null', () {
        expect(fsp.toPosixEscaped(null), '');
      });
      test('empty', () {
        expect(fsp.toPosixEscaped(''), '');
      });
      test('no separator', () {
        expect(fsp.toPosixEscaped('abc.def'), 'abc.def');
      });
      test('general unescaped', () {
        expect(fsp.toPosixEscaped(r'a\b/c.def'), r'a\b/c.def');
      });
      test('general escaped', () {
        expect(fsp.toPosixEscaped(r'a\\b/c.def'),
            (fsp.isPosix ? r'a\\b/c.def' : r'a/b/c.def'));
      });
    });
  });
}

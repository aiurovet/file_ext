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
                append: true),
            r'');
      });
      test('dir - empty - remove', () {
        expect(
            fsp.adjustTrailingSeparator('', FileSystemEntityType.directory,
                append: true),
            r'');
      });
      test('dir - root - add', () {
        expect(
            fsp.adjustTrailingSeparator(sep, FileSystemEntityType.directory,
                append: true),
            sep);
      });
      test('dir - root - remove', () {
        expect(
            fsp.adjustTrailingSeparator(sep, FileSystemEntityType.directory,
                append: true),
            sep);
      });
      test('dir - drive (win) - add', () {
        if (fs.style == FileSystemStyle.windows) {
          expect(
              fsp.adjustTrailingSeparator(r'c:', FileSystemEntityType.directory,
                  append: true),
              r'c:.\');
        }
      });
      test('dir - drive (win) - remove', () {
        if (fs.style == FileSystemStyle.windows) {
          expect(
              fsp.adjustTrailingSeparator(r'c:', FileSystemEntityType.directory,
                  append: false),
              r'c:');
        }
      });
      test('dir - abc - add', () {
        expect(
            fsp.adjustTrailingSeparator('abc', FileSystemEntityType.directory,
                append: true),
            r'abc' + sep);
      });
      test('dir - abc - remove', () {
        expect(
            fsp.adjustTrailingSeparator(
                'abc' + sep, FileSystemEntityType.directory,
                append: false),
            r'abc');
      });
      test('dir - ab/c - add', () {
        expect(
            fsp.adjustTrailingSeparator(
                'ab' + sep + 'c', FileSystemEntityType.directory,
                append: true),
            r'ab' + sep + 'c' + sep);
      });
      test('dir - ab/c - remove', () {
        expect(
            fsp.adjustTrailingSeparator(
                'ab' + sep + 'c', FileSystemEntityType.directory,
                append: false),
            r'ab' + sep + 'c');
      });
      test('file - add', () {
        expect(
            fsp.adjustTrailingSeparator(r'abc', FileSystemEntityType.file,
                append: true),
            r'abc');
      });
      test('file - remove', () {
        expect(
            fsp.adjustTrailingSeparator(r'abc' + sep, FileSystemEntityType.file,
                append: false),
            r'abc' + sep);
      });
    });
    group('PathExt - glob - ${fs.styleName} -', () {
      test('create - null', () {
        expect(fsp.createGlob(null).pattern, r'*');
      });
      test('create - empty', () {
        expect(fsp.createGlob('').pattern, r'*');
      });
      test('create - non-empty', () {
        expect(fsp.createGlob('**/*.{a,b}').pattern, r'**/*.{a,b}{,/**}');
      });
      test('is pattern - null', () {
        expect(PathExt.isGlobPattern(null), false);
      });
      test('is pattern - empty', () {
        expect(PathExt.isGlobPattern(''), false);
      });
      test('is pattern - abc/def.txt', () {
        expect(PathExt.isGlobPattern('abc${sep}def.txt'), false);
      });
      test('is pattern - abc*.txt', () {
        expect(PathExt.isGlobPattern('abc*def.txt'), true);
      });
      test('is pattern - abc.{doc,txt}', () {
        expect(PathExt.isGlobPattern('abc.{doc,txt}'), true);
      });
      test('is pattern - [ab]c.txt', () {
        expect(PathExt.isGlobPattern('[ab]c.txt'), true);
      });
      test('is pattern - !abc.txt', () {
        expect(PathExt.isGlobPattern('!abc.txt'), true);
      });
      test('is recursive - abc/def.txt', () {
        expect(fsp.isRecursivePattern('abc${sep}def.txt'), false);
      });
      test('is recursive - **.txt', () {
        expect(fsp.isRecursivePattern('**.txt'), true);
      });
      test('is recursive - abc/*.txt', () {
        expect(fsp.isRecursivePattern('abc$sep*.txt'), false);
      });
      test('is recursive - ab?c/*.txt', () {
        expect(fsp.isRecursivePattern('ab?c$sep*.txt'), true);
      });
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
    group('PathExt - splitPattern - ${fs.styleName} -', () {
      test('null', () {
        expect(fsp.splitPattern(null), ['', '*']);
      });
      test('empty', () {
        expect(fsp.splitPattern(''), ['', '*']);
      });
      test('abc/', () {
        expect(fsp.splitPattern('abc$sep'), ['abc', '*']);
      });
      test('/abc.def', () {
        expect(fsp.splitPattern('${sep}abc.def'), [sep, 'abc.def']);
      });
      test('Windows root + abc.def', () {
        if (fsp.isPosix) {
          expect(fsp.splitPattern(r'c:\abc.def'), ['', r'c:\abc.def']);
        } else {
          expect(fsp.splitPattern(r'c:\abc.def'), [r'c:\', 'abc.def']);
        }
      });
      test('abc/def', () {
        expect(fsp.splitPattern('abc${sep}def'), ['abc', 'def']);
      });
      test('/ab/cd/efgh.ijk', () {
        expect(fsp.splitPattern('${sep}ab${sep}cd${sep}efgh.ijk'),
            ['${sep}ab${sep}cd', 'efgh.ijk']);
      });
      test('ab/cd*/efgh/**.ijk', () {
        expect(fsp.splitPattern('ab${sep}cd*${sep}efgh$sep**.ijk'),
            ['ab', 'cd*${sep}efgh$sep**.ijk']);
      });
      test('ab <backslash> cd*/efgh/**.ijk', () {
        if (fsp.isPosix) {
          expect(fsp.splitPattern('ab\\cd*${sep}efgh$sep**.ijk'),
              ['', 'ab\\cd*${sep}efgh$sep**.ijk']);
        } else {
          expect(fsp.splitPattern('ab\\cd*${sep}efgh$sep**.ijk'),
              ['ab', 'cd*${sep}efgh$sep**.ijk']);
        }
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

// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/src/file_filter.dart';
import 'package:file_ext/src/memory_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for PathExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final fsp = fs.path;
    final sep = fsp.separator;
    final neg = '-';

    group('FileFilter - ${fs.styleName} -', () {
      test('empty', () {
        var ff = FileFilter('', context: fsp);
        expect(ff.root, '.');
        expect(ff.pattern, '*');
        expect(ff.matchPath, false);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, false);
        expect(ff.regexp, null);
      });
      test('root dir', () {
        var ff = FileFilter('/', context: fsp);
        expect(ff.root, sep);
        expect(ff.pattern, '*');
        expect(ff.matchPath, true);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, false);
        expect(ff.regexp, null);
      });
      test('recursive', () {
        var ff = FileFilter('a/bc/**.txt', context: fsp);
        expect(ff.root, 'a${sep}bc');
        expect(ff.pattern, '**.txt');
        expect(ff.matchPath, true);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, true);
        expect(ff.regexp, null);
      });
      test('regexp', () {
        var ff = FileFilter('^([ab]|[yz])', context: fsp);
        expect(ff.root, '.');
        expect(ff.pattern, '^([ab]|[yz])');
        expect(ff.matchPath, false);
        expect(ff.negative, false);
        expect(ff.glob, null);
        expect(ff.regexp?.pattern, ff.pattern);
      });
      test('negative', () {
        var ff = FileFilter('$neg /a/b/*.txt', context: fsp);
        expect(ff.root, '${sep}a${sep}b');
        expect(ff.pattern, '*.txt');
        expect(ff.matchPath, true);
        expect(ff.negative, true);
        expect(ff.glob?.pattern, '*.txt');
        expect(ff.regexp, null);
      });
      test('escaped negation', () {
        var ff = FileFilter('$neg$neg/a/b/*.txt', context: fsp);
        expect(ff.root, '${sep}a${sep}b');
        expect(ff.pattern, '*.txt');
        expect(ff.matchPath, true);
        expect(ff.negative, true);
        expect(ff.glob?.pattern, '*.txt');
        expect(ff.regexp, null);
      });
      test('negative followed by escaped negation', () {
        var ff = FileFilter('$neg$neg$neg/a/b/*.txt', context: fsp);
        expect(ff.root, '${sep}a${sep}b');
        expect(ff.pattern, '*.txt');
        expect(ff.matchPath, true);
        expect(ff.negative, true);
        expect(ff.glob?.pattern, '*.txt');
        expect(ff.regexp, null);
      });
    });
  });
}

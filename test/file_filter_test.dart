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
    final neg = '<>';

    group('FileFilter - ${fs.styleName} -', () {
      test('empty', () {
        var ff = FileFilter(fs)..setPattern('');
        expect(ff.root, '');
        expect(ff.pattern, '*');
        expect(ff.matchPath, false);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, false);
        expect(ff.regexp, null);
      });
      test('root dir', () {
        var ff = FileFilter(fs)..setPattern('/');
        expect(ff.root, sep);
        expect(ff.pattern, '*');
        expect(ff.matchPath, false);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, false);
        expect(ff.regexp, null);
      });
      test('recursive', () {
        var ff = FileFilter(fs)..setPattern('a/bc/**.txt');
        expect(ff.root, 'a${sep}bc');
        expect(ff.pattern, '**.txt');
        expect(ff.matchPath, false);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, true);
        expect(ff.regexp, null);
      });
      test('recursive including directories', () {
        var ff = FileFilter(fs)..setPattern('a/b*c/**.txt');
        expect(ff.root, 'a');
        expect(ff.pattern, 'b*c$sep**.txt');
        expect(ff.matchPath, true);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, true);
        expect(ff.regexp, null);
      });
      test('regexp', () {
        var ff = FileFilter(fs)..setPattern('^([ab]|[yz])');
        expect(ff.root, '');
        expect(ff.pattern, '^([ab]|[yz])');
        expect(ff.matchPath, false);
        expect(ff.negative, false);
        expect(ff.glob, null);
        expect(ff.regexp?.pattern, ff.pattern);
      });
      test('negative', () {
        var ff = FileFilter(fs)..setPattern('$neg /a/b/*.txt');
        expect(ff.root, '${sep}a${sep}b');
        expect(ff.pattern, '*.txt');
        expect(ff.matchPath, false);
        expect(ff.negative, true);
        expect(ff.glob?.pattern, '*.txt');
        expect(ff.regexp, null);
      });
    });
  });
}

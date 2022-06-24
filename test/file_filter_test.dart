// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for PathExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final fsp = fs.path;
    final sep = fsp.separator;

    group('FileFilter - ${fs.styleName} -', () {
      test('empty', () {
        var ff = FileFilter(fs)..setPatternSync(FilePattern(''));
        expect(ff.dirName, '');
        expect(ff.pattern, '*');
        expect(ff.matchWholePath, false);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, false);
        expect(ff.regExp, null);
      });
      test('root dir', () {
        var ff = FileFilter(fs)..setPatternSync(FilePattern('/'));
        expect(ff.dirName, sep);
        expect(ff.pattern, '*');
        expect(ff.matchWholePath, false);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, false);
        expect(ff.regExp, null);
      });
      test('recursive', () {
        var ff = FileFilter(fs);
        ff.setPatternSync(FilePattern('a/bc/**.txt'));
        expect(ff.dirName, 'a${sep}bc');
        expect(ff.pattern, '**.txt');
        expect(ff.matchWholePath, false);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, true);
        expect(ff.regExp, null);
      });
      test('recursive including directories', () {
        var ff = FileFilter(fs)..setPatternSync(FilePattern('a/b*c/**.txt'));
        expect(ff.dirName, 'a');
        expect(ff.pattern, 'b*c$sep**.txt');
        expect(ff.matchWholePath, true);
        expect(ff.negative, false);
        expect(ff.glob?.recursive, true);
        expect(ff.regExp, null);
      });
      test('regexp', () {
        var ff = FileFilter(fs)..setPatternSync(FilePattern('^([ab]|[yz])'));
        expect(ff.dirName, '');
        expect(ff.pattern, '^([ab]|[yz])');
        expect(ff.matchWholePath, false);
        expect(ff.negative, false);
        expect(ff.glob, null);
        expect(ff.regExp?.pattern, ff.pattern);
      });
      test('negative', () {
        var ff = FileFilter(fs)
          ..setPatternSync(FilePattern('/a/b/*.txt', negative: true));
        expect(ff.dirName, '${sep}a${sep}b');
        expect(ff.pattern, '*.txt');
        expect(ff.matchWholePath, false);
        expect(ff.negative, true);
        expect(ff.glob?.pattern, '*.txt');
        expect(ff.regExp, null);
      });
    });
  });
}

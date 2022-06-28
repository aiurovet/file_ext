// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for FilePattern
///
void main() {
  group('FilePattern -', () {
    test('constructor - default', () {
      final fp = FileFilter('abc');
      expect(fp.isCaseSensitive, null);
      expect(fp.isNegative, false);
      expect(fp.isRegular, false);
      expect(fp.pattern, 'abc');
      expect(fp.isUnicode, false);
    });
    test('constructor - case-sensitive', () {
      final fp = FileFilter('abc', isCaseSensitive: true);
      expect(fp.isCaseSensitive, true);
    });
    test('constructor - case-insensitive', () {
      final fp = FileFilter('abc', isCaseSensitive: false);
      expect(fp.isCaseSensitive, false);
    });
    test('constructor - negative', () {
      final fp = FileFilter('abc', isNegative: true);
      expect(fp.isNegative, true);
    });
    test('constructor - regular', () {
      final fp = FileFilter('abc', isRegular: true);
      expect(fp.isRegular, true);
    });
    test('constructor - unicode 1', () {
      final fp = FileFilter('abc\\p{}', isRegular: true);
      expect(fp.isUnicode, true);
    });
    test('constructor - unicode 2', () {
      final fp = FileFilter('abc\u{10000}');
      expect(fp.isUnicode, true);
    });
  });
}

// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file_ext/file_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for FilePattern
///
void main() {
  group('FilePattern -', () {
    test('constructor - default', () {
      final fp = FilePattern('abc');
      expect(fp.caseSensitive, null);
      expect(fp.negative, false);
      expect(fp.regular, false);
      expect(fp.string, 'abc');
      expect(fp.unicode, false);
    });
    test('constructor - case-sensitive', () {
      final fp = FilePattern('abc', caseSensitive: true);
      expect(fp.caseSensitive, true);
    });
    test('constructor - case-insensitive', () {
      final fp = FilePattern('abc', caseSensitive: false);
      expect(fp.caseSensitive, false);
    });
    test('constructor - negative', () {
      final fp = FilePattern('abc', negative: true);
      expect(fp.negative, true);
    });
    test('constructor - regular', () {
      final fp = FilePattern('abc', regular: true);
      expect(fp.regular, true);
    });
    test('constructor - unicode 1', () {
      final fp = FilePattern('abc\\p{}', regular: true);
      expect(fp.unicode, true);
    });
    test('constructor - unicode 2', () {
      final fp = FilePattern('abc\u{10000}');
      expect(fp.unicode, true);
    });
  });
}

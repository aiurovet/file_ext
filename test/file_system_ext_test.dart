// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:file/file.dart';
import 'package:file_ext/file_ext.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

/// A helper to create file in memory and check success (non-blocking)
///
Future<void> createFile(FileSystem fs, String dirName, String fileName) async {
  final filePath = fs.path.join(dirName, fileName);
  final file = fs.file(filePath);

  await file.create(recursive: true);

  if (!(await file.exists())) {
    throw Exception('Failed to create file: "$filePath"');
  }
}

/// A helper to create all files in memory and check success (non-blocking)
///
Future<void> createFiles(FileSystem fs, String top, String sub1, String sub2) async {
    await createFile(fs, top, 'file11.doc');
    await createFile(fs, top, 'file12.txt');
    await createFile(fs, top, 'file13.docx');

    await createFile(fs, sub1, 'file21.doc');
    await createFile(fs, sub1, 'file22.txt');
    await createFile(fs, sub1, 'file23.docx');

    await createFile(fs, sub2, 'file31.doc');
    await createFile(fs, sub2, 'file32.txt');
    await createFile(fs, sub1, 'file33.docx');
}

/// A helper to create file in memory and check success (blocking)
///
void createFileSync(FileSystem fs, String dirName, String fileName) {
  final filePath = fs.path.join(dirName, fileName);
  final file = fs.file(filePath);

  file.createSync(recursive: true);

  if (!file.existsSync()) {
    throw Exception('Failed to create file: "$filePath"');
  }
}


/// A helper to create all files in memory and check success (non-blocking)
///
void createFilesSync(FileSystem fs, String top, String sub1, String sub2) {
    createFileSync(fs, top, 'file11.doc');
    createFileSync(fs, top, 'file12.txt');
    createFileSync(fs, top, 'file13.docx');

    createFileSync(fs, sub1, 'file21.doc');
    createFileSync(fs, sub1, 'file22.txt');
    createFileSync(fs, sub1, 'file23.docx');

    createFileSync(fs, sub2, 'file31.doc');
    createFileSync(fs, sub2, 'file32.txt');
    createFileSync(fs, sub1, 'file33.docx');
}
/// A suite of tests for FileSystemExt
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final top = fs.path.absolute('dir');
    final sub1 = fs.path.join(top, 'sub1');
    final sub2 = fs.path.join(sub1, 'sub2');

    group('FileSystemExt - ${fs.getStyleName()} -', () {
      test('forEachEntity - top', () async {
        await createFiles(fs, top, sub1, sub2);

        var flst = await fs.forEachEntity(
            root: top,
            filter: Glob('*.{doc*,tx*,docx}'),
            flags: FileSystemExt.accumulate);
        expect(flst.length, fs.path.isPosix ? 3 : 0);
      });
      test('forEachEntitySync - top', () {
        createFilesSync(fs, top, sub1, sub2);

        var flst = fs.forEachEntitySync(
            root: top,
            filter: Glob('*.{doc*,tx*,docx}'),
            flags: FileSystemExt.accumulate);
        expect(flst.length, fs.path.isPosix ? 3 : 0);
      });
    });
  });
}

// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:io';

/// Portable error printer
///
void printError(Object o) {
  stderr.writeln(o.toString());
}

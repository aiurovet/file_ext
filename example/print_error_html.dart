// Copyright (c) 2022, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:html';

/// Portable error printer
///
void printError(Object o) {
  window.console.error(o.toString());
}

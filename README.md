Extension methods for filesystem and stdin-related manipulations

## Features

Asynchronous and synchronous extension methods to:

- loop through filesystem entities (filtered by multiple Glob patterns in multiple directories) and call user-defined function
- loop through all memory-based filesystems of all styles and call user-defined function (useful for unit tests)
- loop through lines from stdin and call user-defined function or read the whole stdin
- file path API extension:
  - `adjust()`      - convert all path separators to POSIX style
  - `toPosix()`     - convert all path separators to OS-specific style
  - `getFullPath()` - similar to `canonicalize()`, but preserves letter case
  - `isHidden()`    - check whether a given filename starts with the dot or path contains a sub-directory starting with the dot (but not limited to the dots)
  - `isPath()`      - check whether a given string contains directory component or not

## Usage

See under the `Example` tab. All sample code files are under the sub-directory `example`.

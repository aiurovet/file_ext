## 0.5.0

- Changed the return type of callbacks: `bool` to `VisitResult`

## 0.4.0

- Removed `stdin_ext`: use `UtfStdin` from the `utf_ext` package instead

## 0.3.1

- Added year 2023 to copyright

## 0.3.0

- Breaking: removed sync event handlers for FileSystemExt's forEachEntity() and forEachEntitySync() and made async ones to return FutureOr
- Breaking: renamed event handlers for FileSystemExt's forEachEntity() and forEachEntitySync()
- Breaking: StdinExt's forEachLine() and forEachLineSync() handlers get another argument: lineNo
- Bugfix: StdinExt's forEachLine() and forEachLineSync() were always returning 0 as line count

## 0.2.1

- Improved documentation

## 0.2.0

- Breaking: greatly simplified, redundant features removed, stdin and glob extensions added

## 0.1.0

- Initial release.

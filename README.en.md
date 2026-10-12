# StringScanner

StringScanner scans string literals in Swift and Objective-C projects and highlights which strings appear to be localized.

## Features

- Swift (`.swift`) and Objective-C (`.m`, `.h`) string literal scanning
- Localization heuristics for `NSLocalizedString`, `String(localized:)`, `Text`, `LocalizedStringKey`, and more
- **CLI** and **macOS GUI** apps
- Concurrent scanning, JSON/CSV export (GUI)
- Sensible default excludes (tests, dependencies, `Package.swift`, etc.)

## Requirements

- macOS 13.0+
- Swift 5.9+ (see [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md))

## Install

```bash
git clone https://github.com/aSynch1889/StringScanner.git
cd StringScanner
swift build
```

## Usage

### CLI

```bash
.build/debug/stringscanner-cli /path/to/project
.build/debug/stringscanner-cli /path/to/project --stdout
.build/debug/stringscanner-cli /path/to/project -o /tmp/strings.json
```

By default, JSON is written to `./string_scan_results.json` in the **current working directory** (not inside the scanned tree).

### GUI

```bash
swift run StringScanner
```

Select a folder, scan, search results, export JSON or CSV.

## License

Apache License 2.0 — see [LICENSE](LICENSE)

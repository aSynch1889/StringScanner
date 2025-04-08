# StringScanner

StringScanner is a tool for scanning strings in Swift projects. It helps developers quickly identify all strings in a project and determine which ones are localized and which are not.

## Features

- Scan all strings in Swift projects
- Automatically identify localized strings (using NSLocalizedString)
- Support for Swift and Objective-C files (.swift, .m, .h)
- Multi-threaded concurrent scanning for better performance
- JSON output format for easy post-processing
- Automatic exclusion of test files, dependency directories, etc.

## System Requirements

- macOS 13.0 or later
- Swift 5.9 or later

## Installation

### Using Swift Package Manager

1. Clone the repository:
```bash
git clone https://github.com/yourusername/StringScanner.git
cd StringScanner
```

2. Build the project:
```bash
swift build
```

3. Run the tool:
```bash
.build/debug/stringscanner-cli [project-path]
```

## Usage

### Basic Usage

```bash
stringscanner-cli [project-path]
```

If no project path is specified, the current directory will be used as the scan target.

### Output Format

The tool outputs results in JSON format, containing the following information:
- File path
- Line number
- Column number
- String content
- Localization status

Example output:
```json
[
  {
    "file": "/path/to/file.swift",
    "line": 42,
    "column": 10,
    "content": "Hello, World!",
    "isLocalized": false
  }
]
```

## Excluded Directories

The tool automatically excludes the following directories:
- Pods/
- Carthage/
- .swiftpm/
- Tests/
- Test/
- Specs/
- DerivedData/
- build/

## License

MIT License - See [LICENSE](LICENSE) file for details

## Contributing

Issues and Pull Requests are welcome! 
# StringScanner

StringScanner 是一个用于扫描 Swift 项目中字符串的工具。它可以帮助开发者快速找出项目中的所有字符串，并识别哪些字符串已经本地化，哪些还没有。

## 功能特点

- 扫描 Swift 项目中的所有字符串
- 自动识别已本地化的字符串（使用 NSLocalizedString）
- 支持 Swift、Objective-C 文件（.swift, .m, .h）
- 多线程并发扫描，提高性能
- 输出 JSON 格式的结果，便于后续处理
- 自动排除测试文件、依赖库等目录

## 系统要求

- macOS 13.0 或更高版本
- Swift 5.9 或更高版本

## 安装

### 使用 Swift Package Manager

1. 克隆仓库：
```bash
git clone https://github.com/yourusername/StringScanner.git
cd StringScanner
```

2. 构建项目：
```bash
swift build
```

3. 运行工具：
```bash
.build/debug/stringscanner-cli [项目路径]
```

## 使用方法

### 基本用法

```bash
stringscanner-cli [项目路径]
```

如果不指定项目路径，将使用当前目录作为扫描目标。

### 输出格式

工具会输出 JSON 格式的结果，包含以下信息：
- 文件路径
- 行号
- 列号
- 字符串内容
- 是否已本地化

示例输出：
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

## 排除目录

工具会自动排除以下目录：
- Pods/
- Carthage/
- .swiftpm/
- Tests/
- Test/
- Specs/
- DerivedData/
- build/

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 贡献

欢迎提交 Issue 和 Pull Request！

# StringScanner

StringScanner 是一个用于扫描 Swift / Objective-C 项目中字符串的工具。它可以帮助开发者快速找出项目中的所有字符串，并识别哪些字符串已经本地化，哪些还没有。

## 功能特点

- 扫描 Swift、Objective-C 源文件（`.swift`、`.m`、`.h`）中的字符串字面量
- 识别常见本地化 API（`NSLocalizedString`、`String(localized:)`、`Text`、`LocalizedStringKey` 等）
- 提供 **CLI** 与 **macOS GUI** 两种使用方式
- 多线程并发扫描
- 导出 JSON / CSV（GUI）
- 自动排除测试目录、依赖目录、`Package.swift` 等

## 系统要求

- macOS 13.0 或更高版本
- Swift 5.9 或更高版本（详见 [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md)）

## 安装

```bash
git clone https://github.com/aSynch1889/StringScanner.git
cd StringScanner
swift build
```

## 使用方法

### 命令行（CLI）

```bash
# 扫描指定目录，结果写入当前目录 string_scan_results.json
.build/debug/stringscanner-cli /path/to/project

# 仅输出 JSON 到 stdout（便于管道）
.build/debug/stringscanner-cli /path/to/project --stdout

# 指定输出文件
.build/debug/stringscanner-cli /path/to/project -o /tmp/strings.json
```

### 图形界面（GUI）

```bash
swift run StringScanner
# 或
.build/debug/StringScanner
```

在界面中选择项目文件夹，点击 **Start Scan**，可在结果列表中搜索并导出 JSON/CSV。

## 输出格式

JSON 数组，每项包含：`file`、`line`、`column`、`content`、`isLocalized`。

## 排除规则

默认跳过路径组件：`Pods`、`Carthage`、`.swiftpm`、`Tests`、`Test`、`Specs`、`DerivedData`、`build`、`.git`、`.build`、`node_modules`，并跳过 `Package.swift`、`Package.resolved` 及 `*.generated.swift`。

## 许可证

Apache License 2.0 — 详见 [LICENSE](LICENSE)

## 贡献

欢迎提交 Issue 和 Pull Request。

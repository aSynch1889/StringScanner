# Swift 与 swift-syntax 兼容说明

| StringScanner 依赖 | swift-syntax 版本 | 验证过的 Swift 工具链 |
|-------------------|-------------------|------------------------|
| 当前仓库 `Package.resolved` | 509.1.1 | Swift 6.3（Xcode 随附） |

## 升级建议

1. 在本地执行 `swift package update` 前，先查看 [swift-syntax releases](https://github.com/apple/swift-syntax/releases) 与 Swift 版本的对应关系。
2. 升级后运行 `swift build` 与 `swift test`。
3. CI（`.github/workflows/ci.yml`）在 `macos-14` 上执行相同命令作为门禁。

## 最低平台

- macOS 13.0+（见 `Package.swift` `platforms`）

# Mac App Store 上架（付费下载）

本仓库已按 **付费下载（Paid App）** 准备沙盒 GUI。CLI 与官网直装包仍走 GitHub / Cloudflare，不进 App Store。

## 已完成的工程改动

- `project.yml` + XcodeGen → `StringScannerApp.xcodeproj`（Archive 用）
- App Sandbox：`App/StringScanner.entitlements`（用户自选目录读写 + bookmark）
- 选文件夹后持久化 security-scoped bookmark，重启可继续扫上次工程
- `APP_STORE` 编译条件：关闭 GitHub 检查更新；「在 Xcode 中打开」改为 `NSWorkspace`（不 spawn `xed`）
- 占位 App Icon（可替换 `App/Assets.xcassets/AppIcon.appiconset`）

## 一次性：生成本地 Xcode 工程

```bash
cd /path/to/StringScanner
xcodegen generate
open StringScannerApp.xcodeproj
```

在 Xcode → Signing & Capabilities：

1. 勾选你的 **Team**（付费 Apple Developer）
2. Bundle ID 保持 `com.asynch.stringscanner`（若已被占用，改 `project.yml` 后重新 `xcodegen generate`）
3. 确认 entitlements 为 `App/StringScanner.entitlements`

## App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) → My Apps → **+** → macOS App  
2. 平台：Mac；价格：付费（如 USD 4.99 / 9.99）  
3. 类别：Developer Tools  
4. 隐私：不收集数据（Data Not Collected），与当前实现一致  
5. 准备截图：可用 `docs/images/app-en.png` / `app-zh.png`（按 ASC 尺寸要求裁切）  
6. 支持 URL：官网 `https://stringscanner.findo.workers.dev`；隐私政策可先放 GitHub README 段落或独立页  

## 上传构建

1. Scheme 选 **StringScanner**，Destination **Any Mac**  
2. Product → Archive（Release 配置会带上 `APP_STORE`）  
3. Organizer → Distribute App → **App Store Connect**  
4. 在 Connect 里选构建、填审核备注，提交  

### 建议写给审核员的备注（英文）

```text
StringScanner is a developer tool that scans a user-selected project folder
for Swift/Objective-C string literals and localization gaps.

How to test:
1. Launch the app.
2. Click “Change Folder” / “更换文件夹” and select any small Xcode/Swift project.
3. Click Start Scan.
4. Optionally export JSON/CSV/.xcstrings via the Export menu.

The app only reads folders the user explicitly grants via NSOpenPanel
(security-scoped bookmarks). It does not require network access.
```

## 沙盒下的行为差异（相对官网直装）

| 能力 | 官网直装 | App Store |
|------|----------|-----------|
| 选文件夹扫描 / 导出 | ✅ | ✅ |
| 记住上次文件夹 | ✅（bookmark） | ✅ |
| GitHub 检查更新 | ✅ | ❌（用 Store 更新） |
| `xed --line` 跳行 | ✅ | 改为用 Xcode 打开文件 |
| CLI | ✅ 单独包 | ❌ 不上架 |

## 与直装包并存

- `swift build` / `website/scripts/package-downloads.sh`：非沙盒直装，**不**定义 `APP_STORE`  
- `StringScannerApp.xcodeproj` Archive：沙盒 + `APP_STORE`，仅用于 MAS  

换图标或改 Bundle ID 后务必重新 `xcodegen generate`。

# 发布、公证与自动更新

## 版本号

GUI 版本定义在 `Sources/StringScanner/AppVersion.swift`（当前 `1.1.0`）。打 tag 前请同步更新该常量。

## GitHub Release（CI）

推送形如 `v1.1.0` 的 tag 会触发 `.github/workflows/release.yml`：

1. `swift build -c release`
2. 打包 GUI `.app` zip 与 CLI zip
3. 上传到 GitHub Release

本地等价：

```bash
./website/scripts/package-downloads.sh
```

## Apple 公证（可选）

未配置 Developer ID 时，用户首次打开需右键「打开」或清除 quarantine。若有证书：

1. 用 Developer ID Application 签名 `.app`
2. 创建公证凭据 profile：

```bash
xcrun notarytool store-credentials "StringScanner-Notary" \
  --apple-id "YOU@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

3. 打包后提交：

```bash
./scripts/notarize.sh website/dist/downloads/StringScanner-macos-arm64.zip
```

## 自动更新

当前 GUI 通过 GitHub Releases API 做「检查更新」（无需 Sparkle 私钥）。侧边栏偏好设置中可手动检查，并跳转到发布页下载。

若后续接入 [Sparkle](https://sparkle-project.org)：

1. 生成 EdDSA 密钥对
2. 为每个 Release 产出 `appcast.xml`
3. 在应用中嵌入 `SUFeedURL` 与公钥
4. 仍建议先完成 Developer ID 签名 + 公证，否则自动替换安装会失败

官网下载页：https://stringscanner.findo.workers.dev

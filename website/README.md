# StringScanner 推广站

静态落地页，部署到 Cloudflare Workers（免费 `*.workers.dev`），并提供 macOS arm64 安装包下载。

## 本地预览

用任意静态服务器打开 `dist/`，例如：

```bash
cd website/dist && python3 -m http.server 8787
```

## 打包安装包

在仓库根目录：

```bash
chmod +x website/scripts/package-downloads.sh
./website/scripts/package-downloads.sh
```

会生成：

- `dist/downloads/StringScanner-macos-arm64.zip`（GUI `.app`）
- `dist/downloads/stringscanner-cli-macos-arm64.zip`（CLI）

## 部署

```bash
cd website
npx wrangler@4 deploy
```

站点地址形如：`https://stringscanner.<your-subdomain>.workers.dev`

# App Store Connect (StringScanner)

App ID: `6822707418`  
Bundle ID: `com.huazi.stringscanner`  
Version: `1.1.0` (MAC_OS)  
Price: **USD 4.99**

## Locales

| Locale | Role |
|--------|------|
| `en-US` | Primary |
| `zh-Hans` | Secondary |

Metadata source files live under `asc/metadata/{en-US,zh-Hans}/`.

## Already applied via `asc`

- Categories: Developer Tools + Utilities
- Age rating: all none
- Content rights: does not use third-party content
- App info name/subtitle/privacy URL (en-US + zh-Hans)
- Version description / keywords / promotional / support / marketing URLs
- Review contact + notes
- Build attached (`1.1.0` / build 1)
- Encryption: exempt (`usesNonExemptEncryption=false`)
- Desktop screenshots (1280×800) for en-US and zh-Hans
- Privacy policy page: https://stringscanner.findo.workers.dev/privacy.html

## Remaining (needs Apple web session)

Public ASC API cannot bootstrap **Pricing & Availability** for a brand-new paid app. Run once:

```bash
asc web auth login --apple-id "YOUR_APPLE_ID"
asc web apps availability create --app 6822707418 --territory "US,CN,GB,JP,DE,FR,CA,AU,HK,TW,SG,KR" --available-in-new-territories true
# then open all territories if needed:
asc app-setup availability edit --app 6822707418 --all-territories --available true
```

Also confirm **App Privacy** is published as “Data Not Collected”:

```bash
asc web privacy pull --app 6822707418 --out ./asc/privacy.json
# edit if needed, then:
asc web privacy apply --app 6822707418 --file ./asc/privacy.json
asc web privacy publish --app 6822707418 --confirm
```

Or do both in the browser:

https://appstoreconnect.apple.com/apps/6822707418/distribution/macos/version/inflate/7684e03b-6b25-4c9b-92c3-824a4717bcf9

## Submit

```bash
asc validate --app 6822707418 --version-id 7684e03b-6b25-4c9b-92c3-824a4717bcf9 --platform MAC_OS
asc review submit --app 6822707418 --version-id 7684e03b-6b25-4c9b-92c3-824a4717bcf9 --build-id 65fd6999-2e2e-4fea-a643-f4825e84cb3f --platform MAC_OS --confirm
```

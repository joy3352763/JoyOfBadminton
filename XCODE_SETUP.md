# Xcode 專案設定備忘錄

> 本文件為 **本機 Build 確認清單**，未完成項目以 ☐ 標記，完成後打勾。

---

## 1. Info.plist 設定

| Build Setting | 目前值 | 需要改為 |
|--------------|--------|----------|
| `GENERATE_INFOPLIST_FILE` | `YES`（預設）| **`No`** |
| `INFOPLIST_FILE` | 空 | `BadmintonScorer/Resources/Info.plist` |

**操作路徑：**
1. 選取 `BadmintonScorer` Target → **Build Settings**
2. 搜尋 `GENERATE_INFOPLIST_FILE` → 改為 **No**
3. 搜尋 `INFOPLIST_FILE` → 填入 `BadmintonScorer/Resources/Info.plist`

> ☐ 確認完成

---

## 2. CI Workflow 確認

| 項目 | 目前預設值 | 確認方式 |
|------|-----------|----------|
| `PROJECT_PATH` | `BadmintonScorer/BadmintonScorer.xcodeproj` | Xcode Navigator 檔名 |
| `SCHEME` | `BadmintonScorer` | Xcode scheme 下拉 或 `xcodebuild -list` |
| Xcode 版本 | `/Applications/Xcode_16.3.app` | `ls /Applications/ \| grep Xcode` |

```bash
xcodebuild -list -project BadmintonScorer/BadmintonScorer.xcodeproj
```

> ☐ 確認完成

---

## 3. Target Membership 確認

所有 `.swift` 加入 `BadmintonScorer` target，測試檔加入 `BadmintonScorerTests` target。

| 目錄 | Target |
|------|--------|
| `BadmintonScorer/App/` | BadmintonScorer |
| `BadmintonScorer/Domain/` | BadmintonScorer |
| `BadmintonScorer/Features/` | BadmintonScorer |
| `BadmintonScorer/Resources/` | BadmintonScorer |
| `BadmintonScorerTests/` | BadmintonScorerTests |

> ☐ 確認完成

---

## 4. Signing & Capabilities

- Bundle ID: 自行填寫（e.g. `com.yourname.JoyOfBadminton`）
- Signing Certificate: 選擇開發者帳號
- Capabilities → **Background Modes** → 勾選 **Audio, AirPlay, and Picture in Picture**
  （對應 `Info.plist` 中的 `UIBackgroundModes: audio`）

> ☐ 確認完成

---

## 5. 首次 Build 驗證步驟

```bash
# 1. Build
xcodebuild build \
  -project BadmintonScorer/BadmintonScorer.xcodeproj \
  -scheme BadmintonScorer \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug

# 2. 單元測試
xcodebuild test \
  -project BadmintonScorer/BadmintonScorer.xcodeproj \
  -scheme BadmintonScorer \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

> ☐ Build Succeeded  
> ☐ All tests passed (目標 24 tests: 16 unit + 8 integration)

---

## 6. 實機測試

| 測試項目 | 驗收標準 |
|---------|----------|
| 相機權限彈窗 | 首次啟動顯示，說明文字正確 |
| 麥克風權限彈窗 | 首次啟動顯示，說明文字正確 |
| 錄影啟動 | `RecordingState` 變為 `.recording` |
| 暫停 / 繼續 | State 正確切換，Banner 文字同步 |
| 停止 → 存檔 | State 變為 `.saved(url:)`，可在 Files App 找到 .mp4 |
| 計分 + 錄影同時 | 無 UI 卡頓，30 分封頂正確關局 |
| iPad 橫向 / 直向 | 版面自適應，Score Panel 位置正確 |
| Undo 連按 5 次 | 分數正確回退，不 crash |

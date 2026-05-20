# 🏸 JoyOfBadminton

[![CI — Build & Test](https://github.com/joy3352763/JoyOfBadminton/actions/workflows/ci.yml/badge.svg)](https://github.com/joy3352763/JoyOfBadminton/actions/workflows/ci.yml)

iOS 羽球雙打錄影計分 App MVP — 純地端、事件溯源架構。

## 功能概覽

- 雙打計分（三戰兩勝、21 分制、30 分封頂）
- 事件級撤銷（Undo 任意一球）
- 比分即時燒錄進影片（Core Graphics + AVAssetWriter）
- iPhone / iPad 雙介面支援
- 發球區、局點、賽點旗標自動計算

## 專案架構

```
BadmintonScorer/
├── App/                    # 入口、根路由
├── Domain/
│   ├── Models/             # Player, Team, MatchSession, MatchEvent, DerivedMatchState
│   ├── Engine/             # MatchEngine（純函數規則引擎）
│   └── Store/              # PlayerStore, MatchStore（ObservableObject）
├── Features/
│   ├── PlayerManagement/   # Epic D1 — 球員 CRUD
│   ├── MatchSetup/         # Epic D2 — 三步驟精靈
│   ├── Scoring/            # Epic E（iPhone / iPad 計分頁）
│   ├── Overlay/            # Epic F（預覽疊加層）
│   └── Recording/          # Epic G（AVFoundation 錄影）
└── Resources/
```

## Epic 進度

| Epic | 內容 | 狀態 |
|------|------|------|
| A | Domain Models | ✅ 完成 |
| B | MatchEngine 規則引擎 | ✅ 完成 |
| C | 單元測試（16 項） | ✅ 完成 |
| D | SwiftUI 賽前 UI（PlayerManagement + MatchSetup） | ✅ 完成 |
| E | 計分頁 UI（iPhone / iPad） | 🔲 待實作 |
| F | Overlay ViewModel + 預覽層 | 🔲 待實作 |
| G | RecorderPipeline | 🔲 待實作 |
| H | 整合驗收 | 🔲 待實作 |

## 環境需求

- Xcode 16.3+
- iOS 16.0+
- Swift 5.9+

## CI 設定

本專案使用 **GitHub Actions** 自動在每次 push / PR 時執行 `xcodebuild build` 與 `xcodebuild test`。

### ❗ 需要在 Xcode 中確認並更新 `.github/workflows/ci.yml`

| 項目 | 目前設定 | 如何確認 |
|------|-----------|----------|
| `PROJECT_PATH` | `BadmintonScorer/BadmintonScorer.xcodeproj` | 對照 Xcode Navigator 中 `.xcodeproj` 檔名 |
| `SCHEME` | `BadmintonScorer` | Xcode 工具列左上 scheme 下拉，或執行 `xcodebuild -list` |
| Xcode 版本 | `/Applications/Xcode_16.3.app` | `ls /Applications/ \| grep Xcode` |

確認後只需移除 workflow 中的 `# ❗ 待確認` 註記即可。

### 手動檢查可用 scheme

```bash
# 在 repo 根目錄執行
xcodebuild -list -project BadmintonScorer/BadmintonScorer.xcodeproj
```

## 建立 Xcode 專案

1. Xcode → **File → New → Project → iOS App**
2. Product Name: `BadmintonScorer`，Interface: SwiftUI，Include Tests
3. 將此 repo 的 `BadmintonScorer/` 資料夾內容拖入對應 Group
4. `⌘B` Build、`⌘U` 執行測試

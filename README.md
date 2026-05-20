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
| A | Domain Models（Player / Team / MatchSession） | ✅ 完成 |
| B | MatchEngine 規則引擎 | ✅ 完成 |
| C | 單元測試（16 項） | ✅ 完成 |
| D | SwiftUI 賽前 UI | ✅ 完成 |
| E | 計分頁 UI（iPhone / iPad） | 🔲 待實作 |
| F | Overlay ViewModel + 預覽層 | 🔲 待實作 |
| G | RecorderPipeline | 🔲 待實作 |
| H | 整合驗收 | 🔲 待實作 |

---

## Epic D 完成度明細

### D1 — PlayerManagementView ✅

| 功能 | 狀態 | 說明 |
|------|------|------|
| 球員列表 | ✅ | `List` + `insetGrouped`，shortName 圓形徽章 + displayName |
| 新增球員 | ✅ | 右上角按鈕開啟 Sheet → `PlayerFormView(mode: .add)` |
| 編輯球員 | ✅ | 左滑 → 鉛筆按鈕 → `PlayerFormView(mode: .edit(player))` |
| 刪除球員 | ✅ | 左滑紅色垃圾桶 或 Edit 模式批次刪除 |
| shortName 截斷 | ✅ | 超過 4 字自動截斷、強制大寫輸入 |
| 表單驗證 | ✅ | shortName 空白時「儲存」disabled；錯誤訊息 inline 顯示 |
| Empty State | ✅ | 無球員時顯示圖示 + 說明文字 + 一鍵新增按鈕 |
| PlayerStore 整合 | ✅ | `@EnvironmentObject` 讀寫，變更自動持久化至 UserDefaults |

### D2 — MatchSetupView ✅

| 功能 | 狀態 | 說明 |
|------|------|------|
| Step 0 — 選 A 隊 | ✅ | 隊名、縮寫（限 4 字）、ColorPicker、球員 1/2 下拉選擇 |
| Step 1 — 選 B 隊 | ✅ | 同上；PlayerPickerRow 自動排除對方已選球員 |
| Step 2 — 設定發球 | ✅ | Segmented 選發球隊、可點選行選發球員 / 接發球員 |
| 跨隊防重複選人 | ✅ | `excluding` 同時排除己方另一人與對方已選球員 |
| 步驟驗證 | ✅ | 每步「下一步」前驗證，錯誤訊息 inline 顯示 |
| 上一步導航 | ✅ | Step 1/2 左上角顯示 `chevron.left` 返回 |
| Color → Hex 轉換 | ✅ | `Color.toHex()` extension，傳入 `Team(colorHex:)` |
| 建立 MatchSession | ✅ | 呼叫 `onSessionCreated(session)` callback 後 dismiss |

### ⚠️ 已知待補項目（Epic E 完成後一併補齊）

| 項目 | 說明 |
|------|------|
| App 根路由整合 | 尚未建立 `ContentView` / `AppView` 將 D1、D2 串接至 E |
| `PlayerStore` 人數不足提示 | MatchSetupView 入口可加防呄：< 4 人時顯示提示带導入 D1 |

---

## 環境需求

- Xcode 16.3+
- iOS 16.0+
- Swift 5.9+

## CI 設定

本專案使用 **GitHub Actions** 自動在每次 push / PR 時執行 `xcodebuild build` 與 `xcodebuild test`。

### ⚠️ 需要在 Xcode 中確認並更新 `.github/workflows/ci.yml`

| 項目 | 目前設定 | 如何確認 |
|------|---------|---------|
| `PROJECT_PATH` | `BadmintonScorer/BadmintonScorer.xcodeproj` | 對照 Xcode Navigator 中 `.xcodeproj` 檔名 |
| `SCHEME` | `BadmintonScorer` | Xcode 工具列左上 scheme 下拉，或執行 `xcodebuild -list` |
| Xcode 版本 | `/Applications/Xcode_16.3.app` | `ls /Applications/ \| grep Xcode` |

確認後只需移除 workflow 中的 `# ⚠️ 待確認` 註記即可。

### 手動檢查可用 scheme

```bash
xcodebuild -list -project BadmintonScorer/BadmintonScorer.xcodeproj
```

## 建立 Xcode 專案

1. Xcode → **File → New → Project → iOS App**
2. Product Name: `BadmintonScorer`，Interface: SwiftUI，Include Tests
3. 將此 repo 的 `BadmintonScorer/` 資料夾內容拖入對應 Group
4. `⌘B` Build、`⌘U` 執行測試

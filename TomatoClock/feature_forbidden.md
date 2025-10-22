# App 屏蔽功能設計文檔

**功能代號**: Forbidden Apps (Focus Shield)
**版本**: v1.2.0
**狀態**: 📋 規劃中
**日期**: 2025-10-22

---

## 🛡️ 核心設計原則

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  ⚠️  這是一個完全可選的附加功能                              │
│                                                            │
│  ✅ 不修改任何現有代碼邏輯                                   │
│  ✅ 只在現有方法末尾「添加」Shield 調用                      │
│  ✅ 默認關閉，用戶需主動啟用                                │
│  ✅ 功能未啟用時，調用立即返回（零開銷）                     │
│  ✅ 即使出錯，也不影響計時器本身                             │
│  ✅ 向下兼容 iOS 14（功能不顯示）                           │
│                                                            │
│  原有功能（計時器、統計、通知、Dynamic Island）            │
│  保持 100% 不變                                            │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 功能概述

**僅在專注時間（Focus）期間**屏蔽用戶選擇的 app，防止分心。當用戶嘗試打開被屏蔽的 app 時，系統會顯示屏蔽畫面。**休息時間（Break）自動解除屏蔽**，讓用戶自由使用所有 app 放鬆。

### ⚠️ 重要設計原則

**這是一個完全可選的附加功能，不會影響任何現有功能：**

✅ **默認關閉** - 用戶需要主動啟用
✅ **完全獨立** - 不修改現有的計時器、統計、通知、Dynamic Island 等功能
✅ **可隨時停用** - 用戶可以隨時在設置中關閉
✅ **向下兼容** - 對於不支援 iOS 15.0+ 的設備，此功能不顯示
✅ **零侵入** - 即使啟用，也只是在現有流程中「加入」屏蔽邏輯，不改變原有行為

### 核心價值

- **工作時專注**：Focus 期間物理層面防止用戶打開分散注意力的 app
- **休息時放鬆**：Break 期間自動解除限制，真正放鬆
- **自我管理**：用戶可自訂屏蔽清單，適應個人需求
- **視覺提醒**：屏蔽畫面可顯示剩餘專注時間，強化時間意識
- **不影響原功能**：所有現有功能（計時、統計、通知等）保持不變

---

## 技術方案

### iOS Framework 選擇

使用 Apple 提供的 **Family Controls** 框架（iOS 15.0+）：

| Framework | 用途 |
|-----------|------|
| `FamilyControls` | 請求授權、選擇要屏蔽的 app |
| `ManagedSettings` | 應用屏蔽設置 |
| `DeviceActivity` | 監控 app 使用（可選，用於進階功能） |

### 核心 API

```swift
import FamilyControls
import ManagedSettings

// 1. 請求授權
let center = AuthorizationCenter.shared
try await center.requestAuthorization(for: .individual)

// 2. 讓用戶選擇要屏蔽的 app
@State private var selection = FamilyActivitySelection()

FamilyActivityPicker(selection: $selection)

// 3. 應用屏蔽設置
let store = ManagedSettingsStore()
store.shield.applications = selection.applicationTokens
```

---

## 功能設計

### 1. 設置頁面

**位置**: Settings > Focus Shield

**UI 元素**:

```
┌─────────────────────────────────┐
│ ⚙️ Settings                      │
├─────────────────────────────────┤
│                                 │
│ 🛡️ Focus Shield                 │
│   Block apps during focus       │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Enable Focus Shield    [✓]  │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Select Apps to Block        │ │
│ │ 5 apps selected        →    │ │
│ └─────────────────────────────┘ │
│                                 │
│ 💡 How it works                 │
│ • Blocks selected apps during   │
│   Focus time only               │
│ • Automatically unlocks during  │
│   Break time                    │
│                                 │
│ 📊 Current Status               │
│ Shield is: Active 🛡️            │
│ (or: Inactive / Not in Focus)   │
│                                 │
│ ℹ️  Requires Screen Time        │
│    permission to work           │
│                                 │
└─────────────────────────────────┘
```

**狀態指示器說明**:
- 顯示當前屏蔽是否啟用
- 實時更新（監聽計時器狀態變化）
- 幫助用戶確認功能正在工作

### 2. App 選擇介面

使用系統提供的 `FamilyActivityPicker`：

- ✅ 顯示所有已安裝的 app（含 icon 和名稱）
- ✅ 支援搜尋
- ✅ 支援多選
- ✅ 分類顯示（社交、娛樂、遊戲等）
- ✅ 系統原生設計，用戶體驗一致

### 3. 屏蔽畫面

當用戶嘗試打開被屏蔽的 app 時，iOS 會顯示：

**預設畫面**（無自訂）:
```
┌─────────────────────────────────┐
│                                 │
│          🔒                     │
│                                 │
│     App is Limited              │
│                                 │
│   This app is not available     │
│                                 │
└─────────────────────────────────┘
```

**自訂畫面**（iOS 16.0+，使用 `ShieldConfiguration`）:
```
┌─────────────────────────────────┐
│                                 │
│          🍅                     │
│                                 │
│    Stay Focused!                │
│                                 │
│   23:45 remaining               │
│                                 │
│  You chose to focus. Keep going!│
│                                 │
└─────────────────────────────────┘
```

### 4. 授權流程

```
用戶開啟 Focus Shield
    ↓
檢查是否已授權
    ↓
否 → 顯示說明對話框
    ↓
請求 Family Controls 授權
    ↓
授權成功 → 顯示 App 選擇器
授權失敗 → 顯示錯誤提示
```

**說明對話框文案**:
```
┌─────────────────────────────────┐
│ 🛡️ Enable Focus Shield          │
├─────────────────────────────────┤
│                                 │
│ TomatoClock needs Screen Time   │
│ permission to help you stay     │
│ focused.                        │
│                                 │
│ This allows the app to:         │
│ • Block distracting apps        │
│ • During your focus sessions    │
│                                 │
│ Your data stays private and     │
│ is never shared.                │
│                                 │
│ ┌─────────────┐ ┌─────────────┐ │
│ │   Cancel    │ │  Continue   │ │
│ └─────────────┘ └─────────────┘ │
└─────────────────────────────────┘
```

---

## 實現計畫

### Phase 1: 基礎功能 (v1.2.0)

#### 1.1 添加 Capability
- [ ] 在 Xcode 中添加 "Family Controls" capability
- [ ] 更新 entitlements 文件

#### 1.2 創建設置 UI
- [ ] 新增 `FocusShieldSettingsView.swift`
- [ ] 整合到主設置頁面
- [ ] 實現開關控制

#### 1.3 授權管理
- [ ] 創建 `FocusShieldService.swift`
- [ ] 實現授權請求邏輯
- [ ] 處理授權狀態變化

#### 1.4 App 選擇
- [ ] 整合 `FamilyActivityPicker`
- [ ] 儲存選擇的 app tokens
- [ ] 實現選擇持久化（UserDefaults 或 Core Data）

#### 1.5 屏蔽邏輯
- [ ] 在 TimerEngine 各方法末尾添加 Shield 調用
  - [ ] `start()` - Focus 模式時啟用
  - [ ] `pause()` - 解除屏蔽
  - [ ] `resume()` - Focus 模式時重新啟用
  - [ ] `handleCompletion()` - 解除屏蔽
  - [ ] `reset()` - 解除屏蔽
- [ ] 實現 app 啟動時的狀態同步
  - [ ] 在 AppDelegate/SceneDelegate 添加 `syncShieldStateWithTimer()`
  - [ ] 讀取 TimerData 並根據當前狀態決定屏蔽狀態
  - [ ] 處理狀態過期的情況

#### 1.6 測試

**功能測試**:
- [ ] 測試授權流程
- [ ] 測試 app 屏蔽/解除
- [ ] 測試狀態持久化
- [ ] 測試邊界情況（app 在背景時開始 Focus、強制關閉等）

**⚠️ 回歸測試（確保不影響現有功能）**:
- [ ] **計時器基礎功能**：Start/Pause/Resume/Reset 在未啟用 Shield 時行為完全不變
- [ ] **Focus/Break 切換**：自動切換邏輯不受影響
- [ ] **統計數據**：Session 計數、完成次數等數據正確
- [ ] **通知**：完成通知正常發送
- [ ] **Dynamic Island**：Live Activity 顯示不受影響
- [ ] **持久化**：計時器狀態保存/讀取不受影響
- [ ] **iOS 14 設備**：在不支援 Focus Shield 的設備上，app 正常運行（功能不顯示）
- [ ] **未授權情況**：如果用戶拒絕 Screen Time 授權，計時器功能完全正常
- [ ] **錯誤情況**：即使 Shield 服務崩潰，計時器繼續正常工作

### Phase 1.5: UI 增強（可選）

#### 1.7 計時器主界面狀態指示
- [ ] 在計時器主畫面添加小圖示指示屏蔽狀態
  - Focus 運行且 Shield 啟用：顯示 🛡️ 圖示
  - Break 運行或 Shield 停用：不顯示圖示
- [ ] 點擊圖示可快速進入 Shield 設置

**UI 示意**:
```
┌─────────────────────────────────┐
│      FOCUS TIME           🛡️    │ ← 小圖示表示屏蔽啟用中
│                                 │
│         24:58                   │
│                                 │
│     [Pause] [Reset]             │
└─────────────────────────────────┘
```

### Phase 2: 進階功能 (v1.3.0)

#### 2.1 自訂屏蔽畫面 (iOS 16.0+)
- [ ] 實現 `ShieldConfigurationProvider`
- [ ] 設計自訂屏蔽畫面
- [ ] 顯示剩餘專注時間
- [ ] 顯示激勵文字

#### 2.2 智能建議
- [ ] 分析用戶使用習慣
- [ ] 建議常用的分散注意力 app
- [ ] 快速設置模板（社交媒體、遊戲、娛樂等）

#### 2.3 統計數據
- [ ] 記錄屏蔽次數（用戶嘗試打開被屏蔽 app 的次數）
- [ ] 顯示「節省的時間」
- [ ] 整合到現有統計頁面

---

## 代碼結構

```
TomatoClock/
├── Core/
│   ├── Services/
│   │   ├── FocusShieldService.swift          // 核心屏蔽邏輯
│   │   └── FocusShieldAuthManager.swift      // 授權管理
│   └── Models/
│       └── FocusShieldSettings.swift         // 設置數據模型
├── Features/
│   └── FocusShield/
│       ├── Views/
│       │   ├── FocusShieldSettingsView.swift // 設置頁面
│       │   ├── AppSelectionView.swift        // App 選擇器封裝
│       │   └── AuthorizationPromptView.swift // 授權說明
│       └── ViewModels/
│           └── FocusShieldViewModel.swift    // ViewModel
└── Extensions/
    └── FocusShield/
        └── ShieldConfigurationExtension.appex // Shield 配置擴展 (iOS 16+)
```

---

## 技術細節

### 1. 數據持久化

由於 `FamilyActivitySelection` 的 tokens 無法直接序列化，需要特殊處理：

```swift
// 儲存
let defaults = UserDefaults.standard
let encoder = JSONEncoder()
if let encoded = try? encoder.encode(selection.applicationTokens) {
    defaults.set(encoded, forKey: "shieldedApps")
}

// 讀取
let decoder = JSONDecoder()
if let data = defaults.data(forKey: "shieldedApps"),
   let tokens = try? decoder.decode(Set<ApplicationToken>.self, from: data) {
    store.shield.applications = tokens
}
```

### 2. 與計時器集成（零侵入式）

**關鍵原則：只添加代碼，不修改現有邏輯**

在 `TimerEngine.swift` 中的現有方法**末尾**添加 Focus Shield 調用：

```swift
func start() throws {
    // === 現有代碼開始（完全不修改）===
    guard currentData.state.canStart else {
        throw TimerError.invalidStateTransition(...)
    }

    // ... 所有現有的計時器啟動邏輯 ...

    stateSubject.send(.running)

    if #available(iOS 16.1, *) {
        startLiveActivity()
    }

    saveState()
    // === 現有代碼結束 ===

    // ✅ 新增：Focus Shield 邏輯（在最後添加）
    // 只在 Focus 模式時啟用屏蔽，Break 和 Long Break 不啟用
    if #available(iOS 15.0, *), currentData.mode == .focus {
        FocusShieldService.shared.enableShield()
    }
}

func pause() throws {
    // === 現有代碼（完全不修改）===
    // ... 所有現有邏輯 ...
    // === 現有代碼結束 ===

    // ✅ 新增：暫停時解除屏蔽（無論是 Focus 還是 Break）
    if #available(iOS 15.0, *) {
        FocusShieldService.shared.disableShield()
    }
}

func resume() throws {
    // === 現有代碼（完全不修改）===
    // ... 所有現有邏輯 ...
    // === 現有代碼結束 ===

    // ✅ 新增：Resume 時根據模式決定是否啟用屏蔽
    // Resume Focus → 重新啟用
    // Resume Break/Long Break → 保持不屏蔽
    if #available(iOS 15.0, *), currentData.mode == .focus {
        FocusShieldService.shared.enableShield()
    }
}

func handleCompletion() {
    // === 現有代碼（完全不修改）===
    // ... 所有現有邏輯 ...
    // === 現有代碼結束 ===

    // ✅ 新增：完成時解除屏蔽（Focus 或 Break 完成都解除）
    // 理由：下一階段由 start() 決定是否啟用
    if #available(iOS 15.0, *) {
        FocusShieldService.shared.disableShield()
    }
}

func reset() {
    // === 現有代碼（完全不修改）===
    // ... 所有現有邏輯 ...
    // === 現有代碼結束 ===

    // ✅ 新增：重置時解除屏蔽
    if #available(iOS 15.0, *) {
        FocusShieldService.shared.disableShield()
    }
}
```

**重要說明**:
- ✅ 所有 Shield 調用都包裹在 `@available` 檢查中，確保向下兼容
- ✅ 如果 Focus Shield 未啟用，`enableShield()` 和 `disableShield()` 內部會立即返回，不執行任何操作
- ✅ 這些調用是**附加的**，不會影響現有的返回值、拋出錯誤、狀態變化等
- ✅ 即使 Shield 服務崩潰，也不會影響計時器本身（使用 try? 或內部錯誤處理）

### 3. FocusShieldService 實現（安全防護）

```swift
import Combine
import FamilyControls
import ManagedSettings

@available(iOS 15.0, *)
class FocusShieldService: ObservableObject {
    static let shared = FocusShieldService()

    @Published var isEnabled: Bool = false  // 用戶是否啟用此功能
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    private let store = ManagedSettingsStore()
    private var cancellables = Set<AnyCancellable>()
    private var selectedApps: Set<ApplicationToken> = []

    private init() {
        // 從 UserDefaults 讀取啟用狀態
        isEnabled = UserDefaults.standard.bool(forKey: "focusShieldEnabled")

        // 監聽授權狀態
        AuthorizationCenter.shared.$authorizationStatus
            .sink { [weak self] status in
                self?.authorizationStatus = status
            }
            .store(in: &cancellables)

        // 讀取已保存的 app 清單
        loadSelectedApps()
    }

    /// 啟用屏蔽 - 在 Focus 開始時調用
    func enableShield() {
        // ⚠️ 關鍵：如果功能未啟用或沒有選擇 app，立即返回
        guard isEnabled, !selectedApps.isEmpty else {
            return
        }

        // ⚠️ 錯誤處理：即使失敗也不影響主程序
        do {
            store.shield.applications = selectedApps
            print("✅ [Focus Shield] Enabled for \(selectedApps.count) apps")
        } catch {
            print("❌ [Focus Shield] Failed to enable: \(error)")
            // 不拋出錯誤，不影響計時器
        }
    }

    /// 解除屏蔽 - 在 Break/Pause/Reset 時調用
    func disableShield() {
        // ⚠️ 關鍵：總是嘗試解除，確保狀態一致
        do {
            store.shield.applications = nil
            print("✅ [Focus Shield] Disabled")
        } catch {
            print("❌ [Focus Shield] Failed to disable: \(error)")
            // 不拋出錯誤，不影響計時器
        }
    }

    // ... 其他方法（授權請求、app 選擇等）...
}
```

**安全保障**:
1. ✅ 使用 `guard` 確保功能未啟用時立即返回
2. ✅ 所有錯誤都被捕獲，不會影響調用者
3. ✅ `disableShield()` 總是執行，確保在任何情況下都能解除屏蔽
4. ✅ 使用單例模式，確保狀態一致性

### 4. 屏蔽配置（iOS 16+）

需要創建 App Extension:

```swift
import ManagedSettings
import ManagedSettingsUI

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: .init(red: 1.0, green: 0.3, blue: 0.3),
            icon: .init(systemName: "tomato.fill"),
            title: .init(
                text: "Stay Focused!",
                color: .label
            ),
            subtitle: .init(
                text: "You chose to focus. Keep going!",
                color: .secondaryLabel
            ),
            primaryButtonLabel: nil,
            primaryButtonBackgroundColor: nil,
            secondaryButtonLabel: nil
        )
    }
}
```

---

## 限制與注意事項

### 系統限制

1. **授權要求**
   - 必須獲得用戶明確授權
   - 授權一旦拒絕，需要用戶手動到設定中修改
   - 無法靜默授權

2. **API 限制**
   - Family Controls 主要設計用於家長控制
   - 某些系統 app 可能無法屏蔽（如設定、電話）
   - 屏蔽設置會在所有登入同一 Apple ID 的設備間同步

3. **版本要求**
   - 基礎功能：iOS 15.0+
   - 自訂屏蔽畫面：iOS 16.0+
   - 需要在專案設定中調整最低支援版本或使用 `@available`

### 隱私考量

1. **數據收集**
   - 只儲存用戶選擇的 app tokens（不含 app 名稱或實際數據）
   - Tokens 只在本地儲存
   - 不上傳到伺服器

2. **透明度**
   - 在授權對話框中清楚說明用途
   - 設置頁面提供資訊按鈕，解釋功能運作方式
   - 允許用戶隨時停用功能

### 用戶體驗考量

1. **誤操作保護**
   - 提供快速停用選項（從通知中心？）
   - 考慮添加「緊急解除」功能
   - 在 Break 時間自動解除屏蔽

2. **教育引導**
   - 首次使用時提供教學
   - 解釋為何需要 Screen Time 權限
   - 提供最佳實踐建議（建議屏蔽哪些 app）

---

## 替代方案

### 方案 A: 提醒而非強制屏蔽

**實現**:
- 監聽 app 切換（使用 `NSWorkspace` 或類似 API - 但 iOS 上不可用）
- 當用戶打開特定 app 時發送通知提醒

**限制**:
- iOS 不允許 app 監聽其他 app 的啟動
- 無法實現

### 方案 B: 整合 Focus Mode

**實現**:
- 引導用戶使用系統的 Focus Mode
- 在 TomatoClock 開始專注時建議用戶啟用 Focus Mode

**優點**:
- 不需要額外權限
- 利用系統原生功能

**缺點**:
- 需要用戶手動操作
- 無法自動化
- 整合度較低

### 方案 C: 僅支援 iOS 16+，使用完整功能

**決策**: 如果目標用戶群主要使用較新設備，可以考慮僅支援 iOS 16+，獲得更好的屏蔽畫面自訂功能。

---

## UI/UX Mock-ups

### 設置頁面流程

```
[Settings 主頁]
       ↓ 點擊 Focus Shield
[授權檢查]
  ↓ 已授權         ↓ 未授權
[設置頁面]      [授權說明頁]
  ↓ 選擇 Apps      ↓ 同意
[App 選擇器]    [系統授權對話框]
  ↓ 完成           ↓ 允許
[設置頁面]      [設置頁面]
 (顯示已選 Apps)
```

### 實際使用流程

```
[用戶啟動 Focus]
       ↓
[TomatoClock 檢查設置]
       ↓
[啟用 app 屏蔽] ← 只在 Focus 模式 + Focus Shield 啟用時
       ↓
[Focus 期間]
  ├─ [嘗試打開被屏蔽的 app]
  │       ↓
  │  [顯示屏蔽畫面]
  │    "Stay Focused!"
  │    "23:45 remaining"
  │       ↓
  │  [用戶返回工作]
  │
  └─ [嘗試打開未屏蔽的 app]
         ↓
    [正常打開]
       ↓
[Focus 時間結束]
       ↓
[自動切換到 Break]
       ↓
[TomatoClock 解除屏蔽] ✅
       ↓
[Break 期間 - 用戶可自由使用所有 app]
  包括之前被屏蔽的 app
       ↓
[Break 時間結束]
       ↓
[自動切換到 Focus]
       ↓
[TomatoClock 重新啟用屏蔽] 🛡️
       ↓
[循環繼續...]
```

---

## 成功指標

### 技術指標
- [ ] 授權成功率 > 70%
- [ ] 屏蔽啟用延遲 < 1 秒
- [ ] 解除屏蔽延遲 < 1 秒
- [ ] 零崩潰率

### 用戶指標
- [ ] 功能啟用率 > 30%（在嘗試功能的用戶中）
- [ ] 持續使用率 > 60%（啟用後 7 天仍在使用）
- [ ] 用戶回饋正面評價 > 4.0/5.0

---

## 時程規劃

| 階段 | 任務 | 預計時間 |
|------|------|----------|
| 研究 | 學習 Family Controls API | 2-3 天 |
| 設計 | UI/UX 設計和 Mock-ups | 1-2 天 |
| 開發 | Phase 1 基礎功能 | 5-7 天 |
| 測試 | 功能測試和邊界測試 | 2-3 天 |
| 開發 | Phase 2 進階功能 | 3-4 天 |
| 優化 | 性能和 UX 優化 | 1-2 天 |
| **總計** | | **14-21 天** |

---

## 參考資源

### Apple 官方文檔
- [Family Controls Framework](https://developer.apple.com/documentation/familycontrols)
- [ManagedSettings Framework](https://developer.apple.com/documentation/managedsettings)
- [DeviceActivity Framework](https://developer.apple.com/documentation/deviceactivity)
- [Screen Time API](https://developer.apple.com/documentation/screentime)

### 範例專案
- [Apple Sample Code: Screen Time API](https://developer.apple.com/documentation/familycontrols/creating_a_screen_time_api_client)

### WWDC Sessions
- WWDC 2021: Meet the Screen Time API
- WWDC 2022: What's new in Screen Time API

---

## 問題與討論

### Q1: 如果用戶在 Focus 期間關閉 TomatoClock app 會怎樣？

**A**: 屏蔽設置會持續生效，因為它是由系統的 `ManagedSettings` 管理，不依賴 app 運行狀態。但需要確保：

**實現要求**:
1. 在 app 終止前保存完整狀態（現有的 `saveState()` 已實現）
2. 在 `AppDelegate` 或 `SceneDelegate` 的 app 啟動時添加屏蔽狀態檢查：

```swift
// 在 app 啟動或進入前景時
@available(iOS 15.0, *)
private func syncShieldStateWithTimer() {
    // 讀取當前計時器狀態
    guard let timerData = persistence.loadTimerData(),
          !timerData.isStale else {
        // 狀態過期，解除屏蔽
        FocusShieldService.shared.disableShield()
        return
    }

    // 檢查當前應該在哪個階段
    if timerData.state == .running {
        // 如果是 Focus 模式且功能啟用，確保屏蔽生效
        if timerData.mode == .focus {
            FocusShieldService.shared.enableShield()
        } else {
            // 如果是 Break 模式，確保屏蔽已解除
            FocusShieldService.shared.disableShield()
        }
    } else {
        // 其他狀態（paused, ready, completed），解除屏蔽
        FocusShieldService.shared.disableShield()
    }
}
```

**關鍵點**:
- ✅ 利用現有的 `TimerData` 持久化
- ✅ 在 app 啟動時同步屏蔽狀態
- ✅ 處理狀態過期的情況（> 1 小時）

### Q2: 如果用戶強制重啟手機會怎樣？

**A**: 需要實現：
1. 持久化當前模式（Focus/Break）、狀態和預計結束時間
2. App 啟動時檢查當前應該在哪個階段：
   - 如果應該在 Focus 期間 → 重新啟用屏蔽
   - 如果應該在 Break 期間 → 確保屏蔽已解除
   - 如果計時器已完全結束 → 確保屏蔽已解除
3. 重要：即使用戶重啟，也要維持正確的 Focus/Break 循環和屏蔽狀態

### Q3: 用戶可以繞過屏蔽嗎？

**A**: 可以，用戶可以：
1. 到設定 > Screen Time 中修改
2. 在 TomatoClock 中停用 Focus Shield
3. 強制關閉 TomatoClock（可能導致屏蔽狀態不一致）

這是**自我管理工具**，不是強制性限制。重點是提供協助，而非完全阻擋。

### Q4: 需要提交 App Store 審核嗎？

**A**: 需要。使用 Family Controls 需要提供審核說明：
1. 說明為何需要這個權限
2. 如何使用（螢幕截圖和說明文字）
3. 確保符合 App Store 審核指南
4. 準備好回答審核團隊的問題

---

## 決策記錄

| 日期 | 決策 | 理由 |
|------|------|------|
| 2025-10-22 | 採用 Family Controls API | Apple 官方解決方案，功能完整且安全 |
| 2025-10-22 | **零侵入式設計** | 完全可選的附加功能，不修改現有代碼邏輯 |
| 2025-10-22 | 默認關閉 | 用戶需主動啟用，避免意外影響使用體驗 |
| 2025-10-22 | 只在 Focus 屏蔽，Break 解除 | 符合番茄鐘理念：工作專注，休息放鬆 |
| 2025-10-22 | Resume 根據模式決定屏蔽 | Resume Focus 重新啟用，Resume Break 保持解除 |
| 2025-10-22 | App 啟動時同步屏蔽狀態 | 確保 app 被終止後重啟時狀態一致 |
| 2025-10-22 | 添加狀態指示器 | 讓用戶清楚知道當前屏蔽是否啟用 |
| TBD | 最低支援版本：iOS 15.0（功能）<br>iOS 14（app 本身） | 新功能需要 iOS 15+，但 app 仍支援 iOS 14 |
| TBD | 自訂屏蔽畫面為可選功能 | iOS 16+ 限定，向下兼容 |

---

## 下一步

1. **審核此文檔**：團隊討論並確認設計方案
2. **創建技術原型**：驗證 Family Controls API 的實際效果
3. **UI 設計**：創建詳細的 UI mock-ups
4. **開始開發**：Phase 1 基礎功能實現

---

**文檔狀態**: 等待審核
**負責人**: TBD
**最後更新**: 2025-10-22

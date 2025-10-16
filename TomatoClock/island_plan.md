# 番茄鐘動態島增強計畫
# TomatoClock Dynamic Island Enhancement Plan

> **專案目標**: 為番茄鐘 app 完善動態島 (Dynamic Island) 倒數計時功能
>
> **創建日期**: 2025-10-14
> **狀態**: 規劃中

---

## 📋 執行摘要

本計畫旨在完善番茄鐘 app 的動態島功能，修復現有數據模型不一致的問題，並實現完整的倒數計時顯示。該功能將為 iPhone 14 Pro 及以上機型用戶提供即時、優雅的番茄鐘倒數顯示。

---

## 🎯 專案目標

### 主要目標
1. **修復數據模型不一致問題** - 統一主 app 和 widget extension 的數據結構
2. **實現自動倒數計時** - 使用 SwiftUI 的 `.timer` 樣式實現自動更新的倒數顯示
3. **完善 UI 展示** - 提供四種展示模式（展開、緊湊、最小化、鎖屏）
4. **優化用戶體驗** - 確保動態島顯示準確、流暢、美觀

### 次要目標
1. 支持不同計時模式的視覺區分（專注時間、短休息、長休息）
2. 顯示當前 session 進度
3. 提供視覺反饋（進度條、顏色變化）
4. 支持點擊動態島返回 app

---

## 🔍 現狀分析

### 現有實現
✅ **已完成的功能**:
- `TimerActivityAttributes.swift` - Activity 數據模型（基礎版）
- `TimerEngine.swift` - Live Activity 生命週期管理
  - `startLiveActivity()` (TomatoClock/Core/Services/TimerEngine.swift:576)
  - `updateLiveActivity()` (TomatoClock/Core/Services/TimerEngine.swift:614)
  - `endLiveActivity()` (TomatoClock/Core/Services/TimerEngine.swift:634)
- `TimerLiveActivityWidget.swift` - Widget UI 實現（部分完成）

### 識別的問題
❌ **需要修復的問題**:

#### 1. 數據模型不一致
**問題描述**: Widget UI 代碼期望的屬性與 `TimerActivityAttributes.ContentState` 實際定義不匹配

**Widget 代碼期望的屬性**:
```swift
// tomatoclockisland/TimerLiveActivityWidget.swift:185-231
context.state.totalDuration      // ❌ 不存在
context.state.modeIdentifier     // ❌ 不存在
context.state.modeDisplayName    // ❌ 不存在
context.state.modeLabel          // ❌ 不存在
context.state.stateIdentifier    // ❌ 不存在
```

**實際定義的屬性**:
```swift
// TomatoClock/Core/Models/TimerActivityAttributes.swift:14-29
struct ContentState: Codable, Hashable {
    var remainingSeconds: TimeInterval  // ✅ 存在
    var mode: TimerMode                 // ✅ 存在（但不能直接序列化用於 widget）
    var state: TimerState               // ✅ 存在（但不能直接序列化用於 widget）
    var displayTime: String             // ✅ 存在
    var timerEndDate: Date              // ✅ 存在
}
```

**根本原因**:
- `TimerMode` 和 `TimerState` 是 enum，需要轉換為 String 以便在 widget 中使用
- Widget extension 無法直接訪問主 app 的 enum 定義的計算屬性

#### 2. Widget Extension Info.plist 配置
**需要確認**: Widget Extension 的 Info.plist 是否包含所有必要配置

**必需配置項**:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

#### 3. 主 App Info.plist 配置
**需要確認**: 主 app 的 Info.plist 是否啟用 Live Activities

**必需配置項**:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

---

## 🛠️ 技術方案

### 階段 1: 修復數據模型（高優先級）

#### 1.1 更新 `TimerActivityAttributes.ContentState`

**文件**: `TomatoClock/Core/Models/TimerActivityAttributes.swift`

**修改內容**:
```swift
struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // ✅ 保留現有屬性
        var remainingSeconds: TimeInterval
        var displayTime: String
        var timerEndDate: Date

        // ⭐ 新增屬性
        var totalDuration: TimeInterval     // 當前階段的總時長
        var modeIdentifier: String          // "focus", "shortBreak", "longBreak"
        var modeDisplayName: String         // "Focus", "Short Break", "Long Break"
        var modeLabel: String               // "FOCUS TIME", "BREAK TIME"
        var stateIdentifier: String         // "ready", "running", "paused", "completed"

        // ❌ 移除 enum 屬性（因為無法在 widget 中使用）
        // var mode: TimerMode
        // var state: TimerState
    }

    var sessionCount: Int
}
```

**遷移策略**:
為保持向後兼容，提供便利初始化方法：
```swift
extension TimerActivityAttributes.ContentState {
    init(
        remainingSeconds: TimeInterval,
        totalDuration: TimeInterval,
        mode: TimerMode,
        state: TimerState,
        displayTime: String,
        timerEndDate: Date
    ) {
        self.remainingSeconds = remainingSeconds
        self.totalDuration = totalDuration
        self.modeIdentifier = mode.rawValue
        self.modeDisplayName = mode.displayName
        self.modeLabel = mode.label
        self.stateIdentifier = state.rawValue
        self.displayTime = displayTime
        self.timerEndDate = timerEndDate
    }
}
```

#### 1.2 更新 `TimerEngine` 中的 Live Activity 調用

**文件**: `TomatoClock/Core/Services/TimerEngine.swift`

**需要更新的方法**:
1. `startLiveActivity()` (行 576-611)
2. `updateLiveActivity()` (行 614-631)

**修改示例**:
```swift
@available(iOS 16.1, *)
private func startLiveActivity() {
    endLiveActivity()

    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
        print("Live Activities are not enabled")
        return
    }

    let remaining = currentData.currentRemaining()
    let timerEndDate = Date().addingTimeInterval(remaining)

    let attributes = TimerActivityAttributes(
        sessionCount: sessionManager.currentProgress.completedCount
    )

    // ⭐ 使用新的初始化方法
    let contentState = TimerActivityAttributes.ContentState(
        remainingSeconds: remaining,
        totalDuration: currentData.totalDuration,
        mode: currentData.mode,
        state: currentData.state,
        displayTime: remaining.formatAsMMSS(),
        timerEndDate: timerEndDate
    )

    do {
        let activity = try Activity<TimerActivityAttributes>.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil),
            pushType: nil
        )
        currentActivity = activity
        print("✅ Live Activity started: \(activity.id)")
    } catch {
        print("❌ Failed to start Live Activity: \(error)")
    }
}
```

#### 1.3 同步 Widget Extension 的 `TimerActivityAttributes.swift`

**文件**: `tomatoclockisland/TimerActivityAttributes.swift`

**操作**: 確保該文件與主 app 的定義完全一致

**建議**:
- 創建共享的 Swift 文件，或
- 使用 Target Membership 將主 app 的文件共享給 widget extension

### 階段 2: 完善動態島 UI（中優先級）

#### 2.1 優化緊湊模式倒數計時

**文件**: `tomatoclockisland/TimerLiveActivityWidget.swift`

**當前實現** (行 83-88):
```swift
compactTrailing: {
    snapshot.timerText()  // ✅ 使用 .timer 樣式，自動更新
        .font(.caption)
        .bold()
        .monospacedDigit()
        .foregroundStyle(snapshot.timerColor)
}
```

**優化建議**:
- ✅ 當前實現已使用 `Text(date, style: .timer)`，無需修改
- ⚠️ 確認字體大小和顏色在不同狀態下的可讀性
- 考慮在時間緊急時（< 1 分鐘）改變顏色或樣式

#### 2.2 增強展開模式顯示

**文件**: `tomatoclockisland/TimerLiveActivityWidget.swift`

**當前實現** (行 39-78):
```swift
DynamicIsland {
    DynamicIslandExpandedRegion(.leading) {
        ModeBadge(snapshot: snapshot)
    }

    DynamicIslandExpandedRegion(.center) {
        VStack(alignment: .leading, spacing: 8) {
            Text(context.state.displayTime)  // ⚠️ 使用靜態字串
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(snapshot.statusLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ... 其他區域
}
```

**優化建議**:
```swift
DynamicIslandExpandedRegion(.center) {
    VStack(alignment: .leading, spacing: 8) {
        // ⭐ 改用自動更新的計時器文字
        snapshot.timerText()
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .monospacedDigit()
        Text(snapshot.statusLine)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

#### 2.3 優化鎖屏顯示

**文件**: `tomatoclockisland/TimerLiveActivityWidget.swift`

**當前實現** (行 97-146):
```swift
private struct TimerLockScreenView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ...
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(context.state.displayTime)  // ⚠️ 使用靜態字串
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                snapshot.timerText()  // ✅ 自動更新
                    .font(.title3)
                    .monospacedDigit()
                    .foregroundStyle(snapshot.timerColor)
            }
            // ...
        }
    }
}
```

**優化建議**:
```swift
HStack(alignment: .lastTextBaseline, spacing: 12) {
    // ⭐ 主顯示改用自動更新
    snapshot.timerText()
        .font(.system(size: 56, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.primary)

    // 副顯示可以顯示狀態或其他信息
    Text(snapshot.statusLine)
        .font(.title3)
        .foregroundStyle(.secondary)
}
```

### 階段 3: 配置和驗證（高優先級）

#### 3.1 檢查和更新 Info.plist 文件

**主 App Info.plist** (`TomatoClock/Info.plist`):
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

**Widget Extension Info.plist** (`tomatoclockisland/Info.plist`):
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

#### 3.2 驗證 Target Membership

**確認以下文件的 Target Membership 正確**:

1. **TimerActivityAttributes.swift**
   - ✅ Target: TomatoClock (主 app)
   - ✅ Target: tomatoclockisland (widget extension)
   - ✅ Target: tomatoclockislandExtension (如果存在)

2. **TimerMode.swift** 和 **TimerState.swift**
   - ⚠️ 如果 widget 需要訪問這些 enum，需要添加到 widget target
   - 或者，只在主 app 中使用，widget 中使用 String 表示

### 階段 4: 性能和體驗優化（低優先級）

#### 4.1 添加 Stale Date

**目的**: 避免顯示過時的 Activity

**實現**:
```swift
let staleDate = Calendar.current.date(
    byAdding: .minute,
    value: 2,
    to: Date()
)

let content = ActivityContent(
    state: contentState,
    staleDate: staleDate
)
```

#### 4.2 實現更新節流

**問題**: `handleTick()` 每秒都會調用 `updateLiveActivity()`，可能造成不必要的更新

**優化方案**:
```swift
private var lastLiveActivityUpdate: Date?

private func handleTick() {
    let remaining = currentData.currentRemaining()
    tickSubject.send(remaining)

    currentData = TimerData(...)

    // ⭐ 僅在需要時更新 Live Activity（例如每 5 秒）
    if #available(iOS 16.1, *) {
        let now = Date()
        if lastLiveActivityUpdate == nil ||
           now.timeIntervalSince(lastLiveActivityUpdate!) >= 5.0 {
            updateLiveActivity()
            lastLiveActivityUpdate = now
        }
    }

    if remaining <= 0 {
        handleCompletion()
    }
}
```

**注意**: 由於使用 `Text(date, style: .timer)`，動態島會自動更新倒數，不需要頻繁手動更新 ContentState。只需在狀態變化時更新（如暫停、恢復）。

#### 4.3 增強視覺反饋

**時間緊急提示**:
```swift
var timerColor: Color {
    if isPaused { return .yellow }
    if isCompleted { return .green }

    // ⭐ 剩餘時間 < 1 分鐘時變紅
    if remaining < 60 && !isPaused && !isCompleted {
        return .red
    }

    return .primary
}
```

**進度條脈動動畫**:
```swift
ProgressView(value: snapshot.elapsed, total: snapshot.total)
    .progressViewStyle(.linear)
    .tint(snapshot.accentColor)
    // ⭐ 添加動畫
    .animation(.easeInOut(duration: 0.3), value: snapshot.elapsed)
```

---

## 📝 實施檢查清單

### ✅ 階段 1: 數據模型修復
- [ ] 更新 `TimerActivityAttributes.ContentState` 添加新屬性
- [ ] 移除 enum 屬性，改用 String
- [ ] 添加便利初始化方法
- [ ] 更新 `TimerEngine.startLiveActivity()`
- [ ] 更新 `TimerEngine.updateLiveActivity()`
- [ ] 同步 widget extension 的 `TimerActivityAttributes.swift`
- [ ] 編譯測試確保無錯誤

### ✅ 階段 2: UI 優化
- [ ] 優化展開模式中央區域，使用自動倒數計時
- [ ] 優化鎖屏顯示，使用自動倒數計時
- [ ] 驗證緊湊模式倒數計時正常工作
- [ ] 測試最小化模式顯示

### ✅ 階段 3: 配置驗證
- [ ] 檢查主 app Info.plist 的 `NSSupportsLiveActivities`
- [ ] 檢查 widget Info.plist 的所有必需配置
- [ ] 驗證 Target Membership 設置
- [ ] 測試在真機上的顯示（必須在 iPhone 14 Pro 或更新機型）

### ✅ 階段 4: 性能優化（可選）
- [ ] 添加 stale date 設置
- [ ] 實現更新節流邏輯
- [ ] 添加時間緊急提示
- [ ] 添加進度條動畫

---

## 🧪 測試策略

### 單元測試
1. 測試 `TimerActivityAttributes.ContentState` 的序列化和反序列化
2. 測試便利初始化方法的正確性
3. 測試數據轉換邏輯

### 集成測試
1. 測試 `TimerEngine` 與 Live Activity 的交互
2. 測試開始、暫停、恢復、完成時 Live Activity 的更新
3. 測試模式切換時 Live Activity 的行為

### UI 測試
1. 測試動態島的四種展示模式
2. 測試倒數計時的自動更新
3. 測試不同計時模式的視覺區分
4. 測試點擊動態島返回 app

### 真機測試
1. **必需設備**: iPhone 14 Pro 或更新機型
2. 測試在鎖屏狀態下的顯示
3. 測試在不同 app 中的動態島顯示
4. 測試多個 Live Activity 同時存在的情況
5. 測試長時間運行的穩定性

詳細測試計畫請參考 `island_testplan.md`。

---

## 🚀 部署計畫

### 開發環境要求
- **Xcode**: 15.0 或更新
- **iOS Deployment Target**: iOS 16.1 或更新
- **測試設備**: iPhone 14 Pro 或更新機型

### 發布檢查清單
- [ ] 所有單元測試通過
- [ ] 所有集成測試通過
- [ ] 真機測試通過
- [ ] 代碼審查完成
- [ ] 文檔更新完成
- [ ] 性能測試通過
- [ ] 用戶接受測試（UAT）通過

---

## 📚 參考資源

### Apple 官方文檔
- [ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [Live Activities Documentation](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Dynamic Island Documentation](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Display-live-activities-in-the-Dynamic-Island)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)

### 範例項目
- [Apple Food Truck Sample](https://github.com/apple/sample-food-truck)

### 內部文檔
- `island.md` - 動態島開發指南
- `island_testplan.md` - 測試計畫（待創建）

---

## 📈 成功指標

### 功能性指標
- ✅ 動態島在所有支持的機型上正確顯示
- ✅ 倒數計時自動更新，無需手動刷新
- ✅ 不同計時模式有清晰的視覺區分
- ✅ 點擊動態島可以返回 app

### 性能指標
- ⚡ Live Activity 更新延遲 < 1 秒
- ⚡ 倒數計時顯示與實際時間誤差 < 1 秒
- ⚡ 不會導致 app 卡頓或崩潰
- ⚡ 電池消耗增加 < 5%

### 用戶體驗指標
- 👍 用戶能夠在不打開 app 的情況下查看計時器狀態
- 👍 動態島顯示美觀、信息清晰
- 👍 在不同場景下（鎖屏、其他 app）都能正常工作

---

## 🔄 維護計畫

### 定期檢查
- 每次 iOS 更新後測試動態島功能
- 監控用戶反饋和崩潰報告
- 關注 Apple 關於 Live Activities 的最新指南

### 未來增強
- 添加推送更新支持（使用 pushType: .token）
- 支持 Apple Watch 同步顯示
- 添加更多自定義選項（顏色、主題）
- 支持交互式操作（在動態島中直接暫停/恢復）

---

**文檔版本**: 1.0
**最後更新**: 2025-10-14
**維護者**: TomatoClock Development Team

# 番茄鐘動態島測試計畫
# TomatoClock Dynamic Island Test Plan

> **測試目標**: 驗證番茄鐘 app 動態島功能的正確性、穩定性和用戶體驗
>
> **創建日期**: 2025-10-14
> **測試版本**: v1.0
> **測試週期**: 2-3 週

---

## 📋 文檔概覽

### 相關文檔
- **增強計畫**: `island_plan.md` - 功能設計和實施方案
- **技術指南**: `island.md` - 動態島開發文檔
- **源代碼**:
  - `TomatoClock/Core/Models/TimerActivityAttributes.swift`
  - `TomatoClock/Core/Services/TimerEngine.swift`
  - `tomatoclockisland/TimerLiveActivityWidget.swift`

### 測試範圍
本測試計畫涵蓋番茄鐘動態島功能的以下方面：
- ✅ 數據模型正確性
- ✅ Live Activity 生命週期管理
- ✅ 動態島 UI 顯示
- ✅ 倒數計時自動更新
- ✅ 不同狀態下的行為
- ✅ 性能和穩定性
- ✅ 用戶體驗

---

## 🎯 測試目標

### 主要目標
1. **功能正確性** - 所有動態島功能按預期工作
2. **數據一致性** - 主 app 和 widget 之間的數據同步正確
3. **UI 準確性** - 動態島顯示準確、美觀、易讀
4. **性能穩定性** - 不會導致 app 卡頓、崩潰或電池消耗過大
5. **用戶體驗** - 提供流暢、直觀的用戶體驗

### 成功標準
- 🎯 所有測試用例通過率 ≥ 95%
- 🎯 關鍵功能測試通過率 = 100%
- 🎯 無阻塞性 bug
- 🎯 性能指標滿足要求
- 🎯 用戶接受測試通過

---

## 🛠️ 測試環境

### 硬體需求

#### 必需設備
1. **iPhone 14 Pro** (iOS 16.1+)
   - 用途：動態島基本功能測試
   - 優先級：高

2. **iPhone 15 Pro** (iOS 17.0+)
   - 用途：最新系統兼容性測試
   - 優先級：高

3. **iPhone 16 Pro** (iOS 18.0+)
   - 用途：最新硬體兼容性測試
   - 優先級：中

#### 參考設備（無動態島）
4. **iPhone 13 / iPhone SE** (iOS 16.1+)
   - 用途：確保在不支持動態島的設備上不會崩潰
   - 優先級：中

### 軟體需求
- **Xcode**: 15.0 或更新
- **iOS SDK**: 16.1 或更新
- **測試框架**: XCTest, XCUITest
- **性能分析工具**: Instruments
- **崩潰分析**: Xcode Organizer, Firebase Crashlytics (可選)

### 測試配置
```swift
// 測試配置常量
enum TestConfiguration {
    // 計時器時長（秒）- 用於快速測試
    static let shortFocusDuration: TimeInterval = 10
    static let shortBreakDuration: TimeInterval = 5
    static let longBreakDuration: TimeInterval = 10

    // 標準時長（秒）- 用於真實場景測試
    static let standardFocusDuration: TimeInterval = 25 * 60
    static let standardShortBreak: TimeInterval = 5 * 60
    static let standardLongBreak: TimeInterval = 15 * 60

    // 測試超時（秒）
    static let defaultTimeout: TimeInterval = 10
    static let longTimeout: TimeInterval = 30
}
```

---

## 📝 測試策略

### 測試金字塔

```
        /\
       /  \        E2E Tests (10%)
      /----\       - 真機端到端測試
     /      \      - 用戶場景測試
    /--------\
   /          \    Integration Tests (30%)
  /------------\   - Live Activity 交互測試
 /              \  - 狀態管理測試
/----------------\
  Unit Tests (60%)
  - 數據模型測試
  - 邏輯單元測試
```

### 測試階段

#### 階段 1: 單元測試（第 1-3 天）
- 重點：數據模型、邏輯單元
- 執行者：開發工程師
- 工具：XCTest
- 覆蓋率目標：≥ 80%

#### 階段 2: 集成測試（第 4-7 天）
- 重點：組件交互、Live Activity 管理
- 執行者：開發工程師 + QA
- 工具：XCTest, Instruments
- 覆蓋率目標：≥ 70%

#### 階段 3: UI 測試（第 8-12 天）
- 重點：動態島顯示、用戶交互
- 執行者：QA + 開發工程師
- 工具：XCUITest, 手動測試
- 覆蓋率目標：所有關鍵路徑

#### 階段 4: 真機測試（第 13-17 天）
- 重點：實際使用場景、性能、穩定性
- 執行者：QA + Beta 測試用戶
- 工具：手動測試、性能監控
- 覆蓋率目標：所有主要使用場景

#### 階段 5: 回歸測試（第 18-21 天）
- 重點：確認 bug 修復、避免功能退化
- 執行者：QA
- 工具：自動化測試 + 手動測試
- 覆蓋率目標：全面測試

---

## 🧪 測試用例

### A. 單元測試 (Unit Tests)

#### A.1 數據模型測試

##### A.1.1 `TimerActivityAttributes.ContentState` 序列化測試
```swift
class TimerActivityAttributesTests: XCTestCase {
    func testContentStateEncodingDecoding() {
        // Given
        let original = TimerActivityAttributes.ContentState(
            remainingSeconds: 1500,
            totalDuration: 1500,
            mode: .focus,
            state: .running,
            displayTime: "25:00",
            timerEndDate: Date().addingTimeInterval(1500)
        )

        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try! encoder.encode(original)
        let decoded = try! decoder.decode(
            TimerActivityAttributes.ContentState.self,
            from: data
        )

        // Then
        XCTAssertEqual(decoded.remainingSeconds, original.remainingSeconds)
        XCTAssertEqual(decoded.totalDuration, original.totalDuration)
        XCTAssertEqual(decoded.modeIdentifier, "focus")
        XCTAssertEqual(decoded.stateIdentifier, "running")
        XCTAssertEqual(decoded.displayTime, original.displayTime)
    }
}
```

**驗收標準**:
- ✅ 所有屬性正確序列化和反序列化
- ✅ enum 值正確轉換為 String
- ✅ Date 類型正確處理

##### A.1.2 便利初始化方法測試
```swift
func testContentStateConvenienceInitializer() {
    // Given
    let mode = TimerMode.shortBreak
    let state = TimerState.paused

    // When
    let contentState = TimerActivityAttributes.ContentState(
        remainingSeconds: 300,
        totalDuration: 300,
        mode: mode,
        state: state,
        displayTime: "05:00",
        timerEndDate: Date().addingTimeInterval(300)
    )

    // Then
    XCTAssertEqual(contentState.modeIdentifier, "shortBreak")
    XCTAssertEqual(contentState.modeDisplayName, "Short Break")
    XCTAssertEqual(contentState.modeLabel, "BREAK TIME")
    XCTAssertEqual(contentState.stateIdentifier, "paused")
}
```

**驗收標準**:
- ✅ 從 TimerMode enum 正確提取所有屬性
- ✅ 從 TimerState enum 正確提取狀態標識
- ✅ 所有屬性值與預期一致

##### A.1.3 邊界值測試
```swift
func testContentStateBoundaryValues() {
    // Test zero remaining time
    let zeroTime = TimerActivityAttributes.ContentState(
        remainingSeconds: 0,
        totalDuration: 1500,
        mode: .focus,
        state: .completed,
        displayTime: "00:00",
        timerEndDate: Date()
    )
    XCTAssertEqual(zeroTime.remainingSeconds, 0)

    // Test negative time (should not happen, but handle gracefully)
    let negativeTime = TimerActivityAttributes.ContentState(
        remainingSeconds: -10,
        totalDuration: 1500,
        mode: .focus,
        state: .running,
        displayTime: "25:00",
        timerEndDate: Date().addingTimeInterval(-10)
    )
    XCTAssertTrue(negativeTime.remainingSeconds < 0)

    // Test very long duration
    let longDuration = TimerActivityAttributes.ContentState(
        remainingSeconds: 9999,
        totalDuration: 9999,
        mode: .focus,
        state: .running,
        displayTime: "166:39",
        timerEndDate: Date().addingTimeInterval(9999)
    )
    XCTAssertEqual(longDuration.remainingSeconds, 9999)
}
```

**驗收標準**:
- ✅ 零值正確處理
- ✅ 負值不會導致崩潰（即使不應該出現）
- ✅ 極大值正確處理

#### A.2 TimeInterval 擴展測試

##### A.2.1 時間格式化測試
```swift
extension TimeInterval {
    func formatAsMMSS() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

class TimeIntervalExtensionTests: XCTestCase {
    func testFormatAsMMSS() {
        XCTAssertEqual((0 as TimeInterval).formatAsMMSS(), "00:00")
        XCTAssertEqual((59 as TimeInterval).formatAsMMSS(), "00:59")
        XCTAssertEqual((60 as TimeInterval).formatAsMMSS(), "01:00")
        XCTAssertEqual((3661 as TimeInterval).formatAsMMSS(), "61:01")
        XCTAssertEqual((1500 as TimeInterval).formatAsMMSS(), "25:00")
        XCTAssertEqual((300 as TimeInterval).formatAsMMSS(), "05:00")
        XCTAssertEqual((900 as TimeInterval).formatAsMMSS(), "15:00")
    }
}
```

**驗收標準**:
- ✅ 標準時長格式化正確
- ✅ 邊界值（0秒、59秒、60秒）正確
- ✅ 超過 60 分鐘的時長正確顯示

---

### B. 集成測試 (Integration Tests)

#### B.1 Live Activity 生命週期測試

##### B.1.1 啟動 Live Activity 測試
```swift
class LiveActivityIntegrationTests: XCTestCase {
    var timerEngine: TimerEngine!
    var mockPersistence: MockPersistenceService!
    var mockNotifications: MockNotificationService!
    var mockSessionManager: MockSessionManager!

    override func setUp() {
        super.setUp()
        mockPersistence = MockPersistenceService()
        mockNotifications = MockNotificationService()
        mockSessionManager = MockSessionManager()
        timerEngine = TimerEngine(
            persistence: mockPersistence,
            notifications: mockNotifications,
            sessionManager: mockSessionManager
        )
    }

    @available(iOS 16.1, *)
    func testStartLiveActivityWhenTimerStarts() throws {
        // Given
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw XCTSkip("Live Activities not enabled")
        }

        // When
        try timerEngine.start()

        // Wait for Live Activity to be created
        let expectation = expectation(description: "Live Activity created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Then
        let activities = Activity<TimerActivityAttributes>.activities
        XCTAssertFalse(activities.isEmpty, "Live Activity should be created")

        if let activity = activities.first {
            XCTAssertEqual(activity.content.state.stateIdentifier, "running")
            XCTAssertEqual(activity.content.state.modeIdentifier, "focus")
            XCTAssertGreaterThan(activity.content.state.remainingSeconds, 0)
        }
    }
}
```

**驗收標準**:
- ✅ 計時器啟動時 Live Activity 被創建
- ✅ ContentState 包含正確的數據
- ✅ timerEndDate 設置正確

##### B.1.2 更新 Live Activity 測試
```swift
@available(iOS 16.1, *)
func testUpdateLiveActivityWhenTimerTicks() throws {
    // Given
    try timerEngine.start()

    let activitiesBefore = Activity<TimerActivityAttributes>.activities
    guard let activityBefore = activitiesBefore.first else {
        XCTFail("Live Activity not created")
        return
    }
    let remainingBefore = activityBefore.content.state.remainingSeconds

    // When
    let expectation = expectation(description: "Timer ticks")
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 3.0)

    // Then
    let activitiesAfter = Activity<TimerActivityAttributes>.activities
    guard let activityAfter = activitiesAfter.first else {
        XCTFail("Live Activity disappeared")
        return
    }
    let remainingAfter = activityAfter.content.state.remainingSeconds

    XCTAssertLessThan(remainingAfter, remainingBefore,
                      "Remaining time should decrease")
    XCTAssertEqual(activityAfter.content.state.stateIdentifier, "running")
}
```

**驗收標準**:
- ✅ 計時器倒數時 remainingSeconds 減少
- ✅ timerEndDate 保持不變（或根據邏輯更新）
- ✅ 狀態保持為 "running"

##### B.1.3 暫停 Live Activity 測試
```swift
@available(iOS 16.1, *)
func testEndLiveActivityWhenTimerPauses() throws {
    // Given
    try timerEngine.start()
    let expectation1 = expectation(description: "Activity started")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        expectation1.fulfill()
    }
    wait(for: [expectation1], timeout: 2.0)

    // When
    try timerEngine.pause()

    let expectation2 = expectation(description: "Activity ended")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        expectation2.fulfill()
    }
    wait(for: [expectation2], timeout: 2.0)

    // Then
    let activities = Activity<TimerActivityAttributes>.activities
    XCTAssertTrue(activities.isEmpty, "Live Activity should be ended when paused")
}
```

**驗收標準**:
- ✅ 暫停時 Live Activity 結束
- ✅ 沒有殘留的 Activity

##### B.1.4 完成 Live Activity 測試
```swift
@available(iOS 16.1, *)
func testEndLiveActivityWhenTimerCompletes() throws {
    // Given - Start timer with very short duration
    timerEngine.updateSettings(TimerSettings(
        focusDuration: 2,
        shortBreakDuration: 1,
        longBreakDuration: 1,
        flow: .default
    ))
    try timerEngine.start()

    // When - Wait for completion
    let expectation = expectation(description: "Timer completes")
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 5.0)

    // Then
    let activities = Activity<TimerActivityAttributes>.activities
    XCTAssertTrue(activities.isEmpty,
                  "Live Activity should be ended when timer completes")
}
```

**驗收標準**:
- ✅ 計時器完成時 Live Activity 結束
- ✅ 狀態轉換到 completed

#### B.2 狀態同步測試

##### B.2.1 模式切換同步測試
```swift
func testLiveActivityUpdatesWhenModeSwitches() throws {
    // Given
    if #available(iOS 16.1, *) {
        try timerEngine.start()

        // When
        timerEngine.switchMode(to: .shortBreak)

        let expectation = expectation(description: "Mode switched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Then
        // Activity should be ended because switchMode stops the timer
        let activities = Activity<TimerActivityAttributes>.activities
        XCTAssertTrue(activities.isEmpty,
                      "Live Activity should end when mode switches")
    }
}
```

**驗收標準**:
- ✅ 模式切換時行為正確（根據設計，可能結束或更新）
- ✅ 新模式的數據正確傳遞

##### B.2.2 設置更新同步測試
```swift
@available(iOS 16.1, *)
func testLiveActivityUpdatesWhenSettingsChange() throws {
    // Given
    try timerEngine.start()

    // When
    let newSettings = TimerSettings(
        focusDuration: 30 * 60,
        shortBreakDuration: 10 * 60,
        longBreakDuration: 20 * 60,
        flow: .default
    )
    timerEngine.updateSettings(newSettings)

    let expectation = expectation(description: "Settings updated")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2.0)

    // Then
    let activities = Activity<TimerActivityAttributes>.activities
    if let activity = activities.first {
        // totalDuration should be updated
        XCTAssertEqual(activity.content.state.totalDuration, 30 * 60)
    }
}
```

**驗收標準**:
- ✅ 設置更新時 totalDuration 正確變更
- ✅ 正在運行的計時器正確處理設置更新

---

### C. UI 測試 (UI Tests)

#### C.1 動態島顯示測試

##### C.1.1 緊湊模式顯示測試
**測試步驟**:
1. 啟動 app 並開始計時器
2. 返回主屏幕或切換到其他 app
3. 觀察動態島緊湊模式顯示

**驗收標準**:
- ✅ 左側顯示計時器圖標（🔴）
- ✅ 右側顯示倒數計時（格式：MM:SS）
- ✅ 倒數計時每秒自動更新
- ✅ 文字清晰可讀

**自動化測試**:
```swift
class DynamicIslandUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testCompactModeDisplaysTimer() {
        // Given
        app.buttons["Start"].tap()

        // When
        XCUIDevice.shared.press(.home)

        // Wait for Dynamic Island to appear
        sleep(2)

        // Then
        // Note: XCUITest cannot directly access Dynamic Island
        // This test is a placeholder for manual verification
        // Automated testing requires visual regression testing tools
    }
}
```

**手動測試檢查清單**:
- [ ] 圖標顏色與模式匹配（紅色=專注，青色=短休息，藍色=長休息）
- [ ] 時間格式正確（MM:SS）
- [ ] 倒數流暢，無跳躍
- [ ] 暫停時顯示變黃色
- [ ] 完成時顯示綠色勾選

##### C.1.2 展開模式顯示測試
**測試步驟**:
1. 啟動計時器並顯示緊湊模式
2. 長按或點擊動態島展開

**驗收標準**:
- ✅ 左上顯示模式標籤（如 "FOCUS TIME"）
- ✅ 中央顯示大號倒數時間
- ✅ 右上顯示小號倒數時間和進度條
- ✅ 底部顯示 session 數量和模式描述
- ✅ 所有元素對齊正確、無重疊

**手動測試檢查清單**:
- [ ] 展開動畫流暢
- [ ] 所有文字清晰可讀
- [ ] 進度條準確反映已用時間
- [ ] 顏色主題與模式一致
- [ ] 點擊可返回 app

##### C.1.3 最小化模式顯示測試
**測試步驟**:
1. 同時運行多個 Live Activity（如音樂、計時器）
2. 觀察動態島最小化顯示

**驗收標準**:
- ✅ 顯示單一圖標
- ✅ 圖標與模式匹配
- ✅ 顏色正確

##### C.1.4 鎖屏顯示測試
**測試步驟**:
1. 啟動計時器
2. 鎖定設備
3. 查看鎖屏

**驗收標準**:
- ✅ 鎖屏顯示大型 Live Activity 卡片
- ✅ 顯示當前時間和倒數計時
- ✅ 顯示進度條
- ✅ 顯示狀態標籤
- ✅ 點擊可解鎖並打開 app

#### C.2 狀態變化 UI 測試

##### C.2.1 暫停狀態顯示測試
**測試步驟**:
1. 啟動計時器
2. 暫停計時器
3. 觀察動態島變化

**驗收標準**:
- ✅ Live Activity 應該結束（根據當前設計）
- ✅ 或顯示 "PAUSED" 狀態和黃色標識

##### C.2.2 完成狀態顯示測試
**測試步驟**:
1. 啟動一個短時長計時器（如 5 秒）
2. 等待完成
3. 觀察動態島變化

**驗收標準**:
- ✅ 顯示 "COMPLETED" 或 "DONE"
- ✅ 使用綠色視覺提示
- ✅ 短暫停留後自動消失

##### C.2.3 模式切換顯示測試
**測試步驟**:
1. 完成專注時段
2. 自動切換到休息模式
3. 觀察動態島變化

**驗收標準**:
- ✅ 顏色主題變更
- ✅ 圖標變更
- ✅ 模式標籤更新
- ✅ 時長重置

---

### D. 真機測試 (Device Tests)

#### D.1 設備兼容性測試

##### D.1.1 iPhone 14 Pro 測試
**測試場景**:
- 基本功能測試
- 長時間運行測試（25 分鐘完整專注時段）
- 多任務切換測試

**驗收標準**:
- ✅ 所有功能正常工作
- ✅ 無崩潰
- ✅ 性能流暢

##### D.1.2 iPhone 15 Pro 測試
**測試場景**:
- iOS 17 兼容性測試
- 新系統特性測試

**驗收標準**:
- ✅ 與 iOS 17 系統特性兼容
- ✅ 無警告或廢棄 API 問題

##### D.1.3 iPhone 16 Pro 測試
**測試場景**:
- iOS 18 兼容性測試
- 最新硬體測試

**驗收標準**:
- ✅ 在最新系統和硬體上正常工作

##### D.1.4 非動態島設備測試
**測試設備**: iPhone 13, iPhone SE

**測試場景**:
- 確認不會嘗試顯示動態島
- 鎖屏 Live Activity 顯示測試

**驗收標準**:
- ✅ App 不會崩潰
- ✅ 鎖屏 Live Activity 正常顯示（如果支持）
- ✅ 沒有 UI 問題

#### D.2 使用場景測試

##### D.2.1 完整番茄鐘流程測試
**測試步驟**:
1. 啟動 25 分鐘專注時段
2. 完成後自動進入 5 分鐘休息
3. 再次啟動專注時段
4. 重複 4 個循環後進入長休息

**驗收標準**:
- ✅ 動態島在整個流程中正確顯示
- ✅ 倒數計時準確
- ✅ 自動切換正確
- ✅ Session 計數正確

##### D.2.2 中斷和恢復測試
**測試步驟**:
1. 啟動計時器
2. 接聽電話
3. 返回計時器

**驗收標準**:
- ✅ 通話期間動態島正確顯示
- ✅ 倒數繼續進行
- ✅ 返回後狀態正確

##### D.2.3 通知交互測試
**測試步驟**:
1. 啟動計時器
2. 等待計時器完成
3. 查看完成通知

**驗收標準**:
- ✅ 完成時收到通知
- ✅ 點擊通知可打開 app
- ✅ 動態島與通知協調顯示

##### D.2.4 低電量測試
**測試步驟**:
1. 設備電量 < 20%
2. 啟動計時器
3. 觀察行為

**驗收標準**:
- ✅ 動態島正常工作
- ✅ 電池消耗在可接受範圍內（< 5% per hour）
- ✅ 低電量模式下仍可使用

##### D.2.5 背景運行測試
**測試步驟**:
1. 啟動計時器
2. 將 app 切換到背景
3. 長時間運行（1 小時+）
4. 返回 app

**驗收標準**:
- ✅ 倒數計時準確
- ✅ 動態島持續更新
- ✅ 狀態同步正確
- ✅ 沒有被系統終止

#### D.3 性能測試

##### D.3.1 CPU 使用率測試
**測試工具**: Xcode Instruments - CPU Profiler

**測試步驟**:
1. 啟動 Instruments 連接設備
2. 開始計時器
3. 記錄 5 分鐘的 CPU 使用率

**驗收標準**:
- ✅ 平均 CPU 使用率 < 5%
- ✅ 無 CPU 峰值
- ✅ 無主線程阻塞

##### D.3.2 內存使用測試
**測試工具**: Xcode Instruments - Allocations

**測試步驟**:
1. 啟動 Instruments 連接設備
2. 完整運行多個番茄鐘循環
3. 記錄內存使用情況

**驗收標準**:
- ✅ 無內存洩漏
- ✅ 內存佔用穩定（< 50 MB）
- ✅ 無記憶體增長趨勢

##### D.3.3 電池消耗測試
**測試工具**: Xcode Energy Log

**測試步驟**:
1. 充滿電
2. 啟動計時器
3. 運行 1 小時
4. 記錄電池消耗

**驗收標準**:
- ✅ 電池消耗 < 5% per hour
- ✅ 無異常高功耗操作
- ✅ 能量影響評級 = Low 或 Medium

##### D.3.4 網絡使用測試
**測試工具**: Xcode Instruments - Network

**測試步驟**:
1. 啟動網絡監控
2. 運行計時器
3. 記錄網絡活動

**驗收標準**:
- ✅ 無不必要的網絡請求
- ✅ Live Activity 不依賴網絡（本地更新）

#### D.4 穩定性測試

##### D.4.1 長時間運行測試
**測試場景**: 連續運行 8 小時（完整工作日）

**驗收標準**:
- ✅ 無崩潰
- ✅ 無內存洩漏
- ✅ 倒數計時保持準確
- ✅ UI 反應靈敏

##### D.4.2 重複啟動測試
**測試場景**: 快速啟動、暫停、重置計時器 100 次

**驗收標準**:
- ✅ 無崩潰
- ✅ 無異常狀態
- ✅ Live Activity 正確管理

##### D.4.3 壓力測試
**測試場景**:
- 快速切換模式
- 快速更新設置
- 同時操作多個功能

**驗收標準**:
- ✅ 無崩潰
- ✅ 無 UI 凍結
- ✅ 狀態一致性保持

---

## 🐛 缺陷管理

### 缺陷分類

#### P0 - 阻塞性缺陷
- App 崩潰
- 數據丟失
- 完全無法使用的功能

#### P1 - 嚴重缺陷
- 核心功能不正常
- 嚴重的 UI 問題
- 明顯的性能問題

#### P2 - 一般缺陷
- 次要功能問題
- 輕微的 UI 問題
- 可接受的性能問題

#### P3 - 輕微缺陷
- 文字錯誤
- 美觀問題
- 優化建議

### 缺陷報告模板

```markdown
## Bug #[編號]

**標題**: [簡短描述問題]

**優先級**: P0 / P1 / P2 / P3

**狀態**: Open / In Progress / Fixed / Verified / Closed

**環境**:
- 設備: iPhone 14 Pro
- iOS 版本: 16.1
- App 版本: 1.0.0
- Build: 001

**重現步驟**:
1. 啟動 app
2. 開始計時器
3. [具體操作]

**預期結果**:
[應該發生什麼]

**實際結果**:
[實際發生什麼]

**附件**:
- 截圖: [附上截圖]
- 視頻: [附上視頻]
- 日誌: [附上相關日誌]
- 崩潰報告: [附上崩潰報告]

**影響範圍**:
[影響哪些功能或用戶]

**可能原因**:
[初步分析]

**建議修復**:
[可能的解決方案]
```

---

## 📊 測試報告

### 測試執行報告模板

```markdown
# 測試執行報告

**報告日期**: 2025-10-XX
**測試週期**: Phase X
**測試執行者**: [姓名]

## 測試摘要
- **總測試用例數**: XXX
- **執行用例數**: XXX
- **通過用例數**: XXX
- **失敗用例數**: XXX
- **跳過用例數**: XXX
- **通過率**: XX%

## 缺陷摘要
- **新增缺陷**: XX
  - P0: X
  - P1: X
  - P2: X
  - P3: X
- **已修復缺陷**: XX
- **待修復缺陷**: XX

## 測試亮點
- [成功完成的重要測試]
- [發現的重要問題]
- [性能改進]

## 風險和問題
- [識別的風險]
- [阻塞問題]
- [需要關注的事項]

## 下一步行動
- [待完成的測試]
- [需要修復的缺陷]
- [改進建議]
```

---

## ✅ 測試完成標準

### 發布標準

#### 必須條件
- ✅ 所有 P0 和 P1 缺陷已修復並驗證
- ✅ 核心功能測試通過率 = 100%
- ✅ 整體測試通過率 ≥ 95%
- ✅ 性能指標滿足要求
- ✅ 無已知的崩潰問題
- ✅ 真機測試通過

#### 推薦條件
- ✅ 所有 P2 缺陷已修復或有計劃修復
- ✅ P3 缺陷已評審並接受或修復
- ✅ 代碼審查完成
- ✅ 文檔更新完成
- ✅ Beta 測試反饋積極

### 迴歸測試通過標準
- ✅ 修復的 bug 不再重現
- ✅ 修復沒有引入新的 bug
- ✅ 核心功能未受影響
- ✅ 性能未退化

---

## 📅 測試時間表

### 第一週 (天 1-7)
- **Day 1-2**: 測試環境搭建和配置
- **Day 3-5**: 單元測試開發和執行
- **Day 6-7**: 單元測試結果分析和缺陷修復

### 第二週 (天 8-14)
- **Day 8-10**: 集成測試執行
- **Day 11-12**: UI 自動化測試開發
- **Day 13-14**: 第一輪缺陷修復

### 第三週 (天 15-21)
- **Day 15-17**: 真機測試（基本功能和場景）
- **Day 18-19**: 性能和穩定性測試
- **Day 20-21**: 第二輪缺陷修復和回歸測試

### 第四週（如需要）
- **Day 22-24**: 最終回歸測試
- **Day 25-26**: Beta 測試和用戶反饋
- **Day 27-28**: 最終修復和發布準備

---

## 🛡️ 風險管理

### 識別的風險

#### 高風險
1. **真機測試設備不足**
   - 影響：無法充分測試動態島功能
   - 緩解：優先購買或借用 iPhone 14 Pro+

2. **Live Activity 授權問題**
   - 影響：用戶未啟用 Live Activities 時功能無法使用
   - 緩解：提供引導和提示，優雅降級

3. **iOS 系統更新導致的兼容性問題**
   - 影響：功能在新系統版本上失效
   - 緩解：持續關注 iOS 更新，及時測試

#### 中風險
4. **性能問題**
   - 影響：電池消耗過大或 UI 卡頓
   - 緩解：持續性能監控和優化

5. **Widget Extension 配置錯誤**
   - 影響：Live Activity 無法顯示
   - 緩解：仔細檢查 Info.plist 和 Target 設置

#### 低風險
6. **UI 細節問題**
   - 影響：視覺不美觀
   - 緩解：設計審查和迭代

---

## 📚 附錄

### A. 測試數據

#### 標準計時器時長
```swift
enum TimerDuration {
    static let focus = 25 * 60      // 1500 秒
    static let shortBreak = 5 * 60  // 300 秒
    static let longBreak = 15 * 60  // 900 秒
}
```

#### 測試用時長（快速測試）
```swift
enum TestTimerDuration {
    static let focus = 10           // 10 秒
    static let shortBreak = 5       // 5 秒
    static let longBreak = 10       // 10 秒
}
```

### B. 測試工具清單

#### 自動化測試
- XCTest - 單元測試和集成測試
- XCUITest - UI 自動化測試

#### 性能分析
- Xcode Instruments
  - Time Profiler (CPU)
  - Allocations (內存)
  - Energy Log (電池)
  - Network (網絡)

#### 手動測試
- 真機設備
- 截圖和屏幕錄製工具

#### 缺陷追蹤
- GitHub Issues
- Jira（可選）

### C. 參考文檔
- [Apple - Testing Your App](https://developer.apple.com/documentation/xcode/testing-your-app)
- [Apple - Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- `island.md` - 動態島技術指南
- `island_plan.md` - 增強計畫

---

## 📝 測試簽核

### 測試階段簽核

| 階段 | 負責人 | 狀態 | 完成日期 | 簽名 |
|------|--------|------|----------|------|
| 單元測試 | 開發工程師 | ⬜ Pending | | |
| 集成測試 | 開發工程師 + QA | ⬜ Pending | | |
| UI 測試 | QA | ⬜ Pending | | |
| 真機測試 | QA | ⬜ Pending | | |
| 性能測試 | 開發工程師 | ⬜ Pending | | |
| 回歸測試 | QA | ⬜ Pending | | |
| 最終審核 | Tech Lead | ⬜ Pending | | |

### 發布批准

- [ ] 所有測試階段完成
- [ ] 所有關鍵缺陷已修復
- [ ] 性能指標滿足要求
- [ ] 文檔更新完成
- [ ] 發布說明準備完畢

**測試負責人**: ________________  日期: ________

**開發負責人**: ________________  日期: ________

**產品負責人**: ________________  日期: ________

---

**文檔版本**: 1.0
**最後更新**: 2025-10-14
**下次審查**: 2025-10-21

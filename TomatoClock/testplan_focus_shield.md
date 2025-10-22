# Focus Shield 功能測試計畫

**功能版本**: v1.2.0
**測試計畫版本**: 1.0
**創建日期**: 2025-10-22
**測試負責人**: TBD
**狀態**: 📋 Draft

---

## 目錄

1. [測試目標](#測試目標)
2. [測試範圍](#測試範圍)
3. [測試環境](#測試環境)
4. [測試策略](#測試策略)
5. [詳細測試用例](#詳細測試用例)
6. [回歸測試](#回歸測試)
7. [通過標準](#通過標準)
8. [風險評估](#風險評估)
9. [測試時程](#測試時程)

---

## 測試目標

### 主要目標

1. **功能正確性**：驗證 Focus Shield 在各種場景下正確屏蔽/解除屏蔽 app
2. **零侵入保證**：確保新功能完全不影響現有的計時器、統計、通知、Dynamic Island 功能
3. **用戶體驗**：驗證授權流程、UI 操作流暢，錯誤處理友好
4. **穩定性**：確保在各種異常情況下 app 不崩潰，計時器繼續工作
5. **兼容性**：驗證在不同 iOS 版本、設備上的兼容性

### 成功指標

- ✅ 所有測試用例通過率 ≥ 95%
- ✅ 零崩潰率（包括 Shield 錯誤的情況）
- ✅ 回歸測試 100% 通過
- ✅ 屏蔽/解除延遲 < 2 秒
- ✅ 用戶授權成功率 > 70%（在願意嘗試的用戶中）

---

## 測試範圍

### 包含的功能

✅ **授權管理**
- Family Controls 授權請求
- 授權狀態監聽
- 授權拒絕處理

✅ **App 選擇**
- FamilyActivityPicker 集成
- App 選擇持久化
- 選擇狀態讀取

✅ **屏蔽邏輯**
- Focus 模式啟用屏蔽
- Break 模式解除屏蔽
- 狀態切換時的屏蔽管理
- Pause/Resume 行為

✅ **UI 功能**
- 設置頁面顯示
- 開關控制
- App 清單顯示

✅ **錯誤處理**
- 未授權時的 fallback
- 屏蔽失敗時的處理
- 服務崩潰時的隔離

### 不包含的功能（Phase 2）

❌ 自訂屏蔽畫面（iOS 16+）
❌ 智能建議
❌ 統計數據展示

---

## 測試環境

### 設備要求

| 類型 | 設備 | iOS 版本 | 用途 |
|------|------|----------|------|
| 主要測試 | iPhone 15 Pro | iOS 18.0 | 完整功能測試 |
| 兼容性測試 | iPhone 12 | iOS 15.0 | 最低版本測試 |
| 兼容性測試 | iPhone 11 | iOS 14.0 | 功能不可用測試 |
| 兼容性測試 | iPhone SE (2020) | iOS 17.0 | 小螢幕測試 |
| Simulator | iPhone 15 Pro Simulator | iOS 18.0 | 開發階段測試 |

### 測試數據

- **測試 Apple ID**：需要專用測試帳號
- **測試 App**：Instagram, Twitter, TikTok, YouTube, Safari, Chrome, Games
- **測試計時器設置**：
  - 短 Focus (1 分鐘) - 快速測試
  - 標準 Focus (25 分鐘) - 正常流程
  - 自訂流程（多個 Focus/Break）

### 前置條件

1. ✅ 測試設備已安裝 TomatoClock app (含 Focus Shield 功能)
2. ✅ 測試設備已登入 Apple ID
3. ✅ 測試設備已安裝足夠的第三方 app 供測試
4. ✅ Screen Time 未被企業或家長控制鎖定
5. ✅ 測試設備有穩定的網路連接（首次授權需要）

---

## 測試策略

### 1. 單元測試（Unit Tests）

使用 XCTest 框架測試：

```swift
// FocusShieldServiceTests.swift
- testEnableShieldWhenDisabled()  // 功能關閉時調用
- testEnableShieldWhenNoApps()    // 未選擇 app
- testEnableShieldSuccess()       // 正常啟用
- testDisableShieldAlways()       // 解除總是成功
- testAuthorizationStatusChange() // 授權狀態變化
- testPersistenceLoad()           // 讀取保存的設置
- testPersistenceSave()           // 保存設置
```

### 2. 集成測試（Integration Tests）

測試 Shield 與 TimerEngine 的集成：

```swift
// TimerEngineShieldIntegrationTests.swift
- testFocusStartEnablesShield()       // Focus 啟動時啟用
- testBreakStartDoesNotEnableShield() // Break 不啟用
- testPauseDisablesShield()           // Pause 解除
- testResumeFocusEnablesShield()      // Resume Focus 重新啟用
- testResumeBreakDoesNotEnableShield()// Resume Break 不啟用
- testResetDisablesShield()           // Reset 解除
- testFocusToBreakDisablesShield()    // Focus → Break
- testBreakToFocusEnablesShield()     // Break → Focus
```

### 3. UI 測試（UI Tests）

使用 XCUITest：

```swift
// FocusShieldUITests.swift
- testSettingsPageNavigation()        // 導航到設置頁
- testToggleShield()                  // 開關切換
- testAuthorizationFlow()             // 授權流程
- testAppSelection()                  // App 選擇
- testShieldEnabledIndicator()        // 啟用狀態顯示
```

### 4. 手動測試

詳細測試用例見下一節。

---

## 詳細測試用例

### A. 授權管理 (Authorization)

#### TC-AUTH-001: 首次請求授權
**前置條件**: 未曾授權 Family Controls
**測試步驟**:
1. 開啟 TomatoClock app
2. 進入 Settings
3. 點擊 "Focus Shield"
4. 開啟 "Enable Focus Shield" 開關

**預期結果**:
- ✅ 顯示說明對話框，解釋為何需要權限
- ✅ 點擊 "Continue" 後顯示系統授權對話框
- ✅ 對話框包含 app 名稱和權限說明

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail
**備註**: ___________

---

#### TC-AUTH-002: 授權成功
**前置條件**: 執行 TC-AUTH-001
**測試步驟**:
1. 在系統授權對話框中點擊 "Allow"

**預期結果**:
- ✅ 對話框關閉
- ✅ 自動顯示 FamilyActivityPicker
- ✅ 設置頁面顯示已授權狀態

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-AUTH-003: 授權拒絕
**前置條件**: 執行 TC-AUTH-001
**測試步驟**:
1. 在系統授權對話框中點擊 "Don't Allow"

**預期結果**:
- ✅ 對話框關閉
- ✅ 顯示友好的錯誤提示
- ✅ 提示用戶可到設定中手動授權
- ✅ "Enable Focus Shield" 開關自動關閉
- ✅ 計時器功能完全正常

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-AUTH-004: 已授權狀態啟用功能
**前置條件**: Family Controls 已授權
**測試步驟**:
1. 開啟 "Enable Focus Shield" 開關

**預期結果**:
- ✅ 直接顯示 FamilyActivityPicker，無需重新授權
- ✅ 如果之前已選擇 app，顯示已選擇的 app

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-AUTH-005: 授權被撤銷
**前置條件**: Focus Shield 已啟用並運行中
**測試步驟**:
1. 到 iOS 設定 > Screen Time > Family Controls
2. 撤銷 TomatoClock 的授權
3. 返回 TomatoClock，開始 Focus

**預期結果**:
- ✅ 設置頁面顯示未授權狀態
- ✅ Focus Shield 自動停用
- ✅ 計時器繼續正常工作
- ✅ 不嘗試屏蔽 app（因為沒有權限）
- ✅ Console 記錄授權錯誤但不崩潰

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

### B. App 選擇 (App Selection)

#### TC-SELECT-001: 選擇單個 App
**前置條件**: Focus Shield 已啟用
**測試步驟**:
1. 點擊 "Select Apps to Block"
2. 在 FamilyActivityPicker 中選擇 Instagram
3. 點擊 "Done"

**預期結果**:
- ✅ 設置頁面顯示 "1 app selected"
- ✅ 選擇被保存到 UserDefaults

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SELECT-002: 選擇多個 App
**前置條件**: Focus Shield 已啟用
**測試步驟**:
1. 點擊 "Select Apps to Block"
2. 選擇 Instagram, Twitter, TikTok, YouTube, Safari
3. 點擊 "Done"

**預期結果**:
- ✅ 設置頁面顯示 "5 apps selected"
- ✅ 所有選擇被正確保存

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SELECT-003: 取消選擇
**前置條件**: 已選擇 5 個 app
**測試步驟**:
1. 點擊 "Select Apps to Block"
2. 取消選擇 Instagram 和 Twitter
3. 點擊 "Done"

**預期結果**:
- ✅ 設置頁面顯示 "3 apps selected"
- ✅ 只有 TikTok, YouTube, Safari 被保存

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SELECT-004: 取消所有選擇
**前置條件**: 已選擇至少 1 個 app
**測試步驟**:
1. 點擊 "Select Apps to Block"
2. 取消選擇所有 app
3. 點擊 "Done"

**預期結果**:
- ✅ 設置頁面顯示 "0 apps selected" 或 "No apps selected"
- ✅ 開始 Focus 時不會屏蔽任何 app（因為清單為空）

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SELECT-005: 搜尋 App
**前置條件**: Focus Shield 已啟用
**測試步驟**:
1. 點擊 "Select Apps to Block"
2. 在搜尋框輸入 "Instagram"
3. 選擇搜尋結果中的 Instagram

**預期結果**:
- ✅ 搜尋結果正確顯示 Instagram
- ✅ 選擇後正確保存

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SELECT-006: 持久化 - 重啟後讀取
**前置條件**: 已選擇 5 個 app
**測試步驟**:
1. 完全關閉 TomatoClock app
2. 重新開啟 app
3. 進入 Focus Shield 設置

**預期結果**:
- ✅ 設置頁面顯示 "5 apps selected"
- ✅ 點擊進入選擇器，之前選擇的 app 仍被勾選

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

### C. 屏蔽邏輯 - Focus 模式 (Shield Logic - Focus Mode)

#### TC-SHIELD-001: Focus 啟動時啟用屏蔽
**前置條件**:
- Focus Shield 已啟用
- 已選擇 Instagram, Twitter 作為屏蔽 app
- 計時器在 Ready 狀態，模式為 Focus

**測試步驟**:
1. 點擊 Start 按鈕開始 Focus
2. 將 app 切換到背景
3. 嘗試打開 Instagram

**預期結果**:
- ✅ Focus 計時器正常開始倒數
- ✅ Console 顯示 "✅ [Focus Shield] Enabled for 2 apps"
- ✅ Instagram 被屏蔽，顯示屏蔽畫面
- ✅ 屏蔽畫面顯示 "App is Limited" 或自訂訊息

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SHIELD-002: Focus 期間未屏蔽的 App 正常使用
**前置條件**: 執行 TC-SHIELD-001
**測試步驟**:
1. Focus 運行中
2. 嘗試打開 Messages (未在屏蔽清單中)

**預期結果**:
- ✅ Messages 正常打開，無屏蔽畫面

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SHIELD-003: Focus Pause 時解除屏蔽
**前置條件**: Focus 運行中，屏蔽已啟用
**測試步驟**:
1. 返回 TomatoClock
2. 點擊 Pause 按鈕
3. 將 app 切換到背景
4. 嘗試打開 Instagram

**預期結果**:
- ✅ 計時器暫停
- ✅ Console 顯示 "✅ [Focus Shield] Disabled"
- ✅ Instagram 正常打開，無屏蔽

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SHIELD-004: Focus Resume 時重新啟用屏蔽
**前置條件**: Focus 已暫停，屏蔽已解除
**測試步驟**:
1. 點擊 Resume 按鈕
2. 將 app 切換到背景
3. 嘗試打開 Instagram

**預期結果**:
- ✅ 計時器恢復倒數
- ✅ Console 顯示 "✅ [Focus Shield] Enabled for 2 apps"
- ✅ Instagram 被屏蔽

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SHIELD-005: Focus Reset 時解除屏蔽
**前置條件**: Focus 運行中或已暫停
**測試步驟**:
1. 點擊 Reset 按鈕
2. 確認 Reset
3. 嘗試打開 Instagram

**預期結果**:
- ✅ 計時器重置到 Ready 狀態
- ✅ Console 顯示 "✅ [Focus Shield] Disabled"
- ✅ Instagram 正常打開

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SHIELD-006: Focus 完成自動切換到 Break 時解除屏蔽
**前置條件**:
- Focus Shield 已啟用
- 設置 1 分鐘 Focus 用於快速測試
- 已選擇 Instagram 為屏蔽 app

**測試步驟**:
1. 開始 Focus
2. 確認 Instagram 被屏蔽
3. 等待 1 分鐘 Focus 完成
4. 觀察計時器自動切換到 Short Break
5. 嘗試打開 Instagram

**預期結果**:
- ✅ Focus 完成時顯示完成狀態
- ✅ 1 秒後自動切換到 Short Break
- ✅ Console 顯示 "✅ [Focus Shield] Disabled"
- ✅ Instagram 正常打開（Break 期間無屏蔽）

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

### D. 屏蔽邏輯 - Break 模式 (Shield Logic - Break Mode)

#### TC-SHIELD-007: Short Break 啟動時不啟用屏蔽
**前置條件**:
- 計時器在 Ready 狀態，模式為 Short Break
- 或從上一個測試 TC-SHIELD-006 繼續

**測試步驟**:
1. 如果在 Ready 狀態，點擊 Start 開始 Short Break
2. 將 app 切換到背景
3. 嘗試打開 Instagram

**預期結果**:
- ✅ Short Break 計時器正常開始
- ✅ Console **不**顯示 "Enabled" 訊息
- ✅ Instagram 正常打開，無屏蔽

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SHIELD-008: Long Break 啟動時不啟用屏蔽
**前置條件**: 計時器在 Ready 狀態，模式為 Long Break
**測試步驟**:
1. 手動切換到 Long Break 模式（或完成足夠的循環觸發 Long Break）
2. 點擊 Start
3. 嘗試打開 Instagram

**預期結果**:
- ✅ Long Break 計時器正常開始
- ✅ Instagram 正常打開，無屏蔽

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SHIELD-009: Break Pause 時保持解除狀態
**前置條件**: Short Break 運行中
**測試步驟**:
1. 點擊 Pause
2. 嘗試打開 Instagram

**預期結果**:
- ✅ Break 暫停
- ✅ Instagram 仍然正常打開（保持未屏蔽狀態）

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SHIELD-010: Break Resume 時保持解除狀態
**前置條件**: Short Break 已暫停
**測試步驟**:
1. 點擊 Resume
2. 嘗試打開 Instagram

**預期結果**:
- ✅ Break 恢復倒數
- ✅ Instagram 仍然正常打開

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-SHIELD-011: Break 完成自動切換到 Focus 時啟用屏蔽
**前置條件**:
- Focus Shield 已啟用
- 設置 1 分鐘 Short Break 用於快速測試

**測試步驟**:
1. 開始 Short Break
2. 確認 Instagram 未被屏蔽
3. 等待 1 分鐘 Break 完成
4. 觀察計時器自動切換到 Focus
5. 嘗試打開 Instagram

**預期結果**:
- ✅ Break 完成後自動切換到 Focus
- ✅ Console 顯示 "✅ [Focus Shield] Enabled for X apps"
- ✅ Instagram 被屏蔽

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

### E. 狀態切換循環 (State Transition Cycles)

#### TC-CYCLE-001: 完整的 Focus → Break → Focus 循環
**前置條件**:
- Focus Shield 已啟用
- 設置 1 分鐘 Focus, 30 秒 Short Break

**測試步驟**:
1. 開始 Focus，確認 Instagram 被屏蔽
2. 等待 Focus 完成
3. 自動切換到 Short Break，確認 Instagram 可用
4. 等待 Break 完成
5. 自動切換回 Focus，確認 Instagram 再次被屏蔽

**預期結果**:
- ✅ Focus 期間：Instagram 屏蔽 🛡️
- ✅ Break 期間：Instagram 可用 ✅
- ✅ 下一個 Focus：Instagram 屏蔽 🛡️
- ✅ 整個循環計時器功能正常
- ✅ Dynamic Island 正常顯示（如果支援）

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-CYCLE-002: 手動切換模式
**前置條件**: Focus Shield 已啟用
**測試步驟**:
1. 在 Ready 狀態
2. 使用 UI 切換到 Short Break 模式
3. 點擊 Start，確認 Instagram 未被屏蔽
4. Reset
5. 切換回 Focus 模式
6. 點擊 Start，確認 Instagram 被屏蔽

**預期結果**:
- ✅ 手動切換模式不會自動啟用/解除屏蔽
- ✅ 只有在 Start 時根據模式決定是否啟用屏蔽
- ✅ Focus Start → 屏蔽
- ✅ Break Start → 不屏蔽

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

### F. 背景和生命週期 (Background & Lifecycle)

#### TC-LIFE-001: App 在背景時 Focus 開始
**前置條件**:
- Focus Shield 已啟用
- 計時器在 Ready 狀態（Focus 模式）

**測試步驟**:
1. 開啟 TomatoClock
2. 點擊 Start 開始 Focus
3. **立即**切換到背景（按 Home 鍵或滑動手勢）
4. 等待 2-3 秒
5. 嘗試打開 Instagram

**預期結果**:
- ✅ Focus 計時器在背景繼續運行
- ✅ Instagram 被屏蔽（即使 app 在背景）

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-LIFE-002: App 被完全終止後重啟
**前置條件**:
- Focus Shield 已啟用
- Focus 正在運行中，屏蔽已啟用

**測試步驟**:
1. Focus 運行中，確認 Instagram 被屏蔽
2. 從多工切換器完全關閉 TomatoClock
3. 嘗試打開 Instagram（TomatoClock 已關閉）
4. 重新開啟 TomatoClock

**預期結果**:
- ✅ App 關閉後，屏蔽**仍然生效**（由系統 ManagedSettings 管理）
- ✅ Instagram 仍被屏蔽
- ✅ 重啟 app 後，計時器恢復為 Paused 狀態（根據現有邏輯）
- ✅ app 檢查當前應該在哪個狀態：
  - 如果 Focus 仍在進行中 → 保持屏蔽
  - 如果已切換到 Break → 解除屏蔽

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail
**⚠️ 重要**: 此測試暴露了一個潛在問題 - 需要在 feature_forbidden.md 中補充

---

#### TC-LIFE-003: 手機重啟
**前置條件**:
- Focus Shield 已啟用
- Focus 正在運行中

**測試步驟**:
1. Focus 運行中
2. 記錄當前剩餘時間
3. 重啟手機
4. 重新開啟 TomatoClock

**預期結果**:
- ✅ App 啟動後檢查當前應該在哪個階段
- ✅ 如果 Focus 應該還在進行 → 重新啟用屏蔽
- ✅ 如果已經切換到 Break → 確保屏蔽已解除
- ✅ 如果計時器已完全結束 → 解除屏蔽，回到 Ready

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-LIFE-004: Focus 期間收到電話
**前置條件**: Focus 運行中，屏蔽已啟用
**測試步驟**:
1. Focus 運行中
2. 使用另一支手機撥打電話到測試設備
3. 接聽電話
4. 通話中嘗試打開 Instagram（如果可能）
5. 掛斷電話
6. 嘗試打開 Instagram

**預期結果**:
- ✅ 電話不受影響，可正常接聽
- ✅ 通話結束後，屏蔽仍然生效
- ✅ Instagram 仍被屏蔽

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

### G. 設置和配置 (Settings & Configuration)

#### TC-CONFIG-001: 停用 Focus Shield
**前置條件**:
- Focus Shield 已啟用
- Focus 正在運行中，Instagram 被屏蔽

**測試步驟**:
1. 返回 TomatoClock
2. 進入 Settings > Focus Shield
3. 關閉 "Enable Focus Shield" 開關
4. 返回計時器（Focus 仍在運行）
5. 嘗試打開 Instagram

**預期結果**:
- ✅ 開關關閉
- ✅ Console 顯示 "✅ [Focus Shield] Disabled"
- ✅ Instagram 立即可用（即使 Focus 仍在運行）
- ✅ 計時器繼續正常運行

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-CONFIG-002: 重新啟用 Focus Shield
**前置條件**: Focus Shield 已停用
**測試步驟**:
1. Focus 運行中
2. 開啟 "Enable Focus Shield" 開關
3. 嘗試打開 Instagram

**預期結果**:
- ✅ 開關開啟
- ✅ 如果當前是 Focus 模式，Instagram 立即被屏蔽
- ✅ 如果當前是 Break 模式，Instagram 仍可用

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-CONFIG-003: Focus 期間修改屏蔽清單
**前置條件**:
- Focus Shield 已啟用
- 選擇了 Instagram, Twitter
- Focus 運行中

**測試步驟**:
1. 確認 Instagram 和 Twitter 都被屏蔽
2. 返回 TomatoClock，進入 Shield 設置
3. 修改清單：移除 Instagram，新增 TikTok
4. 返回，嘗試打開 Instagram 和 TikTok

**預期結果**:
- ✅ Instagram 立即可用（已從清單移除）
- ✅ TikTok 立即被屏蔽（新增到清單）
- ✅ Twitter 仍被屏蔽

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

### H. 錯誤處理 (Error Handling)

#### TC-ERROR-001: 未選擇任何 App 時啟動 Focus
**前置條件**:
- Focus Shield 已啟用
- App 清單為空（0 apps selected）

**測試步驟**:
1. 開始 Focus

**預期結果**:
- ✅ Focus 正常開始
- ✅ Console 顯示 Shield 未啟用（因為清單為空）
- ✅ 所有 app 都可正常使用
- ✅ 不崩潰，不顯示錯誤

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-ERROR-002: Shield 服務崩潰
**前置條件**: 開發環境
**測試步驟**:
1. 在 `FocusShieldService.enableShield()` 中手動拋出錯誤
2. 開始 Focus

**預期結果**:
- ✅ Console 顯示錯誤訊息
- ✅ 計時器繼續正常運行
- ✅ App 不崩潰
- ✅ 其他功能（通知、Dynamic Island）不受影響

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-ERROR-003: 屏蔽設置失敗
**前置條件**: 模擬 ManagedSettings 設置失敗
**測試步驟**:
1. （需要特殊測試環境或 mock）
2. 嘗試啟用屏蔽

**預期結果**:
- ✅ Console 記錄錯誤
- ✅ 計時器不受影響
- ✅ App 不崩潰

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

### I. 兼容性測試 (Compatibility)

#### TC-COMPAT-001: iOS 14 設備
**設備**: iPhone 11, iOS 14.0
**測試步驟**:
1. 安裝並開啟 TomatoClock
2. 進入 Settings

**預期結果**:
- ✅ App 正常運行
- ✅ Settings 中**不顯示** Focus Shield 選項（因為 iOS 14 不支援）
- ✅ 所有其他功能正常（計時器、統計、通知）

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-COMPAT-002: iOS 15.0 設備（最低支援版本）
**設備**: iPhone 12, iOS 15.0
**測試步驟**:
1. 安裝並開啟 TomatoClock
2. 進入 Settings > Focus Shield
3. 執行完整授權和屏蔽測試

**預期結果**:
- ✅ Focus Shield 功能完整可用
- ✅ 所有功能正常運作

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-COMPAT-003: 小螢幕設備
**設備**: iPhone SE (2020)
**測試步驟**:
1. 測試 UI 在小螢幕上的顯示
2. 測試 FamilyActivityPicker 的顯示

**預期結果**:
- ✅ UI 沒有截斷或重疊
- ✅ 所有按鈕可點擊
- ✅ FamilyActivityPicker 正常顯示

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-COMPAT-004: 深色模式
**測試步驟**:
1. 開啟系統深色模式
2. 檢查 Focus Shield 設置頁面

**預期結果**:
- ✅ UI 在深色模式下正常顯示
- ✅ 文字清晰可讀
- ✅ 對比度適當

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

## 回歸測試

### 確保新功能不影響現有功能

#### TC-REGRESS-001: 計時器基礎功能（未啟用 Shield）
**前置條件**: Focus Shield **關閉**
**測試步驟**:
1. Start Focus → 確認正常開始
2. Pause → 確認正常暫停
3. Resume → 確認正常恢復
4. Reset → 確認正常重置
5. 切換 Break 模式 → Start → 確認正常

**預期結果**:
- ✅ 所有計時器操作與 Shield 功能添加前完全相同
- ✅ 行為無任何變化

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-REGRESS-002: 自動 Focus/Break 切換
**前置條件**: Focus Shield 關閉
**測試步驟**:
1. 完成一個 Focus 循環
2. 觀察是否正確切換到 Break
3. 完成 Break
4. 觀察是否正確切換回 Focus

**預期結果**:
- ✅ 自動切換邏輯與之前完全相同
- ✅ 切換時間、通知、UI 更新都正常

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-REGRESS-003: 統計數據
**前置條件**: Focus Shield 開啟或關閉（兩種情況都測試）
**測試步驟**:
1. 完成 3 個 Focus session
2. 檢查統計頁面的數據

**預期結果**:
- ✅ Session 計數正確（完成 3 個）
- ✅ 完成次數、總時間等統計數據正確
- ✅ 與 Shield 啟用/停用無關

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-REGRESS-004: 通知
**前置條件**: 通知權限已授予
**測試步驟**:
1. 設置 1 分鐘 Focus
2. 開始 Focus 並切換到背景
3. 等待 Focus 完成

**預期結果**:
- ✅ Focus 完成時收到通知
- ✅ 通知內容正確
- ✅ 點擊通知可返回 app
- ✅ 與 Shield 啟用/停用無關

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-REGRESS-005: Dynamic Island
**前置條件**:
- iPhone 14 Pro 或更新機型
- Focus Shield 開啟或關閉

**測試步驟**:
1. 開始 Focus
2. 切換到背景
3. 觀察 Dynamic Island
4. 等待切換到 Break
5. 觀察 Dynamic Island

**預期結果**:
- ✅ Dynamic Island 正確顯示倒數計時
- ✅ Focus → Break 切換時 Dynamic Island 持續顯示
- ✅ 顯示的模式、時間正確
- ✅ 與 Shield 啟用/停用無關

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-REGRESS-006: 狀態持久化
**前置條件**: Focus Shield 開啟
**測試步驟**:
1. 開始 Focus
2. 等待 30 秒
3. 完全關閉 app
4. 重新開啟 app

**預期結果**:
- ✅ 計時器狀態正確恢復（Paused）
- ✅ 剩餘時間大致正確
- ✅ 模式（Focus）正確
- ✅ 狀態持久化邏輯與之前相同

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

#### TC-REGRESS-007: 性能測試
**測試步驟**:
1. 使用 Instruments 測試 CPU 使用率
2. 測試記憶體使用

**預期結果**:
- ✅ Shield 關閉時：零額外 CPU/記憶體開銷
- ✅ Shield 開啟時：開銷 < 5% CPU, < 10MB 記憶體
- ✅ UI 操作流暢，無卡頓

**實際結果**: ___________
**狀態**: [ ] Pass [ ] Fail

---

## 通過標準

### Phase 1 發布標準

必須達成以下所有條件才能發布 v1.2.0：

#### 功能完整性
- [ ] 所有 A-H 類別測試用例通過率 ≥ 95%
- [ ] 所有 Critical 和 High 優先級缺陷已修復
- [ ] Medium 優先級缺陷 < 3 個

#### 回歸測試
- [ ] 所有回歸測試 100% 通過
- [ ] 確認計時器、統計、通知、Dynamic Island 功能完全不受影響

#### 穩定性
- [ ] 零崩潰率（包括 Shield 錯誤情況）
- [ ] 所有錯誤處理測試通過
- [ ] 記憶體洩漏測試通過

#### 兼容性
- [ ] iOS 14 設備：功能不顯示，app 正常運行
- [ ] iOS 15.0 設備：完整功能正常
- [ ] iOS 17+ 設備：完整功能正常
- [ ] 深色模式測試通過
- [ ] 小螢幕設備測試通過

#### 用戶體驗
- [ ] 授權流程清晰易懂
- [ ] 錯誤訊息友好
- [ ] UI 響應流暢（屏蔽啟用 < 2 秒）

#### 文檔
- [ ] feature_forbidden.md 完整且準確
- [ ] 測試報告完成
- [ ] 已知問題列表更新

---

## 風險評估

### 高風險項目

| 風險 | 影響 | 可能性 | 緩解措施 |
|------|------|--------|----------|
| **授權被拒絕** | 功能無法使用 | 高 | 清晰的說明文案；提供手動授權指引 |
| **App 被終止後狀態不一致** | 屏蔽可能殘留或未正確恢復 | 中 | 實現狀態檢查和恢復邏輯（需補充到 md） |
| **Family Controls API 限制** | 某些系統 app 無法屏蔽 | 中 | 文檔說明限制；不承諾 100% 屏蔽 |
| **多設備同步問題** | 設置在不同設備間不一致 | 低 | 文檔說明；考慮使用 CloudKit 同步（Phase 2） |
| **屏蔽失敗不被察覺** | 用戶以為被屏蔽但實際可用 | 中 | 添加視覺指示器顯示屏蔽狀態 |

### 中風險項目

| 風險 | 影響 | 可能性 | 緩解措施 |
|------|------|--------|----------|
| **性能影響** | App 運行變慢 | 低 | 性能測試；優化 Shield 檢查邏輯 |
| **UI 在小螢幕顯示問題** | iPhone SE 等設備 UI 擁擠 | 低 | 適配小螢幕；測試多種設備 |
| **深色模式對比度** | 文字不清晰 | 低 | 設計審查；深色模式專項測試 |

---

## 測試時程

| 階段 | 活動 | 預計時間 | 負責人 |
|------|------|----------|--------|
| **準備階段** | 測試環境搭建、測試數據準備 | 0.5 天 | TBD |
| **單元測試** | FocusShieldService 單元測試 | 1 天 | 開發 |
| **集成測試** | TimerEngine 集成測試 | 1 天 | 開發 |
| **功能測試** | 執行 TC-AUTH, TC-SELECT, TC-SHIELD, TC-CYCLE | 2 天 | QA |
| **生命週期測試** | 執行 TC-LIFE | 0.5 天 | QA |
| **配置和錯誤** | 執行 TC-CONFIG, TC-ERROR | 0.5 天 | QA |
| **兼容性測試** | 執行 TC-COMPAT（多設備） | 1 天 | QA |
| **回歸測試** | 執行 TC-REGRESS（完整） | 1 天 | QA |
| **缺陷修復** | 修復發現的問題 | 2 天 | 開發 |
| **重測** | 重新測試修復的缺陷 | 1 天 | QA |
| **測試報告** | 編寫測試報告、決策發布 | 0.5 天 | QA Lead |
| **總計** | | **11 天** | |

---

## 測試報告模板

### 測試執行摘要

**測試日期**: ___________
**測試人員**: ___________
**測試版本**: ___________
**測試設備**: ___________

### 測試結果

| 類別 | 總數 | 通過 | 失敗 | 跳過 | 通過率 |
|------|------|------|------|------|--------|
| 授權管理 (A) | 5 | ___ | ___ | ___ | ___% |
| App 選擇 (B) | 6 | ___ | ___ | ___ | ___% |
| Focus 屏蔽 (C) | 6 | ___ | ___ | ___ | ___% |
| Break 屏蔽 (D) | 5 | ___ | ___ | ___ | ___% |
| 狀態循環 (E) | 2 | ___ | ___ | ___ | ___% |
| 生命週期 (F) | 4 | ___ | ___ | ___ | ___% |
| 設置配置 (G) | 3 | ___ | ___ | ___ | ___% |
| 錯誤處理 (H) | 3 | ___ | ___ | ___ | ___% |
| 兼容性 (I) | 4 | ___ | ___ | ___ | ___% |
| **回歸測試** | 7 | ___ | ___ | ___ | ___% |
| **總計** | **45** | ___ | ___ | ___ | ___% |

### 缺陷統計

| 優先級 | Critical | High | Medium | Low | 總計 |
|--------|----------|------|--------|-----|------|
| 數量 | ___ | ___ | ___ | ___ | ___ |

### 主要問題

1. ___________
2. ___________
3. ___________

### 發布建議

- [ ] **建議發布** - 所有標準達成
- [ ] **有條件發布** - 存在 Medium 優先級問題，但不影響核心功能
- [ ] **不建議發布** - 存在 Critical/High 優先級問題

**理由**: ___________

---

## 附錄

### A. 測試數據清單

**屏蔽 App 清單**:
- Instagram
- Twitter (X)
- TikTok
- YouTube
- Facebook
- Reddit
- Safari (測試瀏覽器屏蔽)
- Chrome (測試多個瀏覽器)
- 任何遊戲 app

**未屏蔽 App**（用於驗證選擇性屏蔽）:
- Messages
- Mail
- Notes
- Calendar
- Photos

### B. 控制台日誌檢查點

在測試過程中應觀察的關鍵日誌：

```
✅ [Focus Shield] Enabled for X apps
✅ [Focus Shield] Disabled
✅ [Focus Shield] Updated successfully
❌ [Focus Shield] Failed to enable: <error>
❌ [Focus Shield] Failed to disable: <error>
```

### C. 缺陷報告模板

**缺陷 ID**: FS-XXX
**優先級**: [ ] Critical [ ] High [ ] Medium [ ] Low
**類別**: ___________
**摘要**: ___________

**重現步驟**:
1. ___________
2. ___________

**預期結果**: ___________
**實際結果**: ___________
**截圖/日誌**: ___________
**環境**: iOS 版本、設備型號

---

**文檔版本**: 1.0
**最後更新**: 2025-10-22
**審核狀態**: [ ] Draft [ ] Review [ ] Approved

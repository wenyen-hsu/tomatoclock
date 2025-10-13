# TomatoClock 專案設定指南

## ✅ 已完成的步驟

所有原始碼檔案已經複製到正確位置，並且已修復所有已知問題：

- ✅ 刪除預設檔案（ContentView.swift, Item.swift）
- ✅ 複製所有 18 個 Swift 檔案
- ✅ 修復 Protocols.swift（已加入 `import UserNotifications`）
- ✅ 修復 TomatoClockApp.swift（使用 `Task.detached`）

## 📋 接下來要做的事（在 Xcode 中）

### 步驟 1: 在 Xcode 中加入檔案（5分鐘）

1. **打開專案**
   ```
   /Users/wenhsu/Documents/wenyen/TomatoClockClean/TomatoClock/TomatoClock.xcodeproj
   ```
   （雙擊檔案即可）

2. **加入 App 資料夾**
   - 右鍵點擊左側的 `TomatoClock` 資料夾
   - 選擇 **Add Files to "TomatoClock"...**
   - 導航到：`/Users/wenhsu/Documents/wenyen/TomatoClockClean/TomatoClock/TomatoClock/App`
   - 選擇整個 `App` 資料夾
   - 確認勾選：
     - ✓ **Copy items if needed**
     - ✓ **Create groups**
     - ✓ **Add to targets: TomatoClock**
   - 點擊 **Add**

3. **加入 Core 資料夾**
   - 重複上述步驟
   - 選擇：`/Users/wenhsu/Documents/wenyen/TomatoClockClean/TomatoClock/TomatoClock/Core`
   - 點擊 **Add**

4. **加入 UI 資料夾**
   - 重複上述步驟
   - 選擇：`/Users/wenhsu/Documents/wenyen/TomatoClockClean/TomatoClock/TomatoClock/UI`
   - 點擊 **Add**

5. **加入 Resources 資料夾**
   - 重複上述步驟
   - 選擇：`/Users/wenhsu/Documents/wenyen/TomatoClockClean/TomatoClock/TomatoClock/Resources`
   - 點擊 **Add**

### 步驟 2: 配置顏色（2分鐘）

1. 點擊 **Assets.xcassets**
2. 右鍵點擊 → **New Color Set**
3. 建立以下 4 個顏色：

**PrimaryRed:**
- 名稱：PrimaryRed
- 顏色值：#FF6347

**BackgroundWhite:**
- 名稱：BackgroundWhite
- 顏色值：#FFFFFF

**SecondaryGray:**
- 名稱：SecondaryGray
- 顏色值：#F5F5F5

**TextDark:**
- 名稱：TextDark
- 顏色值：#333333

**如何設定顏色：**
- 點擊顏色方塊
- 選擇 **Show Color Panel**
- 選擇 **Color Sliders** → **RGB Sliders** → **Hex Color #**
- 輸入顏色代碼（例如：FF6347）

### 步驟 3: 設定 Capabilities（2分鐘）

1. 點擊左上角藍色專案圖示
2. 選擇 **TomatoClock** target
3. 點擊 **Signing & Capabilities** 標籤
4. 點擊 **+ Capability**
5. 搜尋並加入：**Push Notifications**
6. 再次點擊 **+ Capability**
7. 搜尋並加入：**Background Modes**
   - 勾選：✓ **Background processing**

### 步驟 4: 設定 Info.plist（1分鐘）

1. 仍在 Target 設定中，點擊 **Info** 標籤
2. 展開 **Custom iOS Target Properties**
3. 找到任一行，按 **+** 加入新項目
4. 輸入：
   ```
   Key: Privacy - User Notifications Usage Description
   Type: String
   Value: We'll notify you when your Pomodoro session completes.
   ```

### 步驟 5: 驗證沒有重複檔案（1分鐘）

1. 點擊專案 → Target → **Build Phases**
2. 展開 **Compile Sources**
3. 確認每個檔案只出現**一次**
4. 如果有重複，選擇並按 **-** 刪除

應該看到這些檔案（共 18 個）：
- AppDelegate.swift
- TomatoClockApp.swift
- TimerMode.swift
- TimerState.swift
- TimerData.swift
- SessionProgress.swift
- TimerError.swift
- Date+Monotonic.swift
- Protocols.swift
- PersistenceService.swift
- NotificationService.swift
- TimerEngine.swift
- SessionManager.swift
- TimerViewModel.swift
- CircularTimerView.swift
- ControlButtons.swift
- AppHeader.swift
- TimerScreen.swift

### 步驟 6: 編譯並執行！（30秒）

1. 選擇模擬器：**iPhone 15 Pro**（上方工具列）
2. 按 **⌘R** 或點擊 ▶️ **Run** 按鈕
3. 🎉 App 應該會啟動！

---

## 🔧 如果遇到錯誤

### "Cannot find type..." 錯誤

**解決方法：**
1. 找到出錯的檔案
2. 點擊該檔案
3. 右側 File Inspector → **Target Membership**
4. 確認 ✓ **TomatoClock** 有打勾

### "Duplicate..." 錯誤

**解決方法：**
1. Build Phases → Compile Sources
2. 找到重複的檔案
3. 刪除多餘的（保留一個即可）

### 顏色找不到

**解決方法：**
1. 確認顏色名稱**完全一致**（大小寫敏感）：
   - `PrimaryRed`（不是 primaryRed）
   - `BackgroundWhite`
   - `SecondaryGray`
   - `TextDark`

### 清理並重建

如果問題持續：
```
⌘⇧K  (Product → Clean Build Folder)
```

然後關閉 Xcode，執行：
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

重新打開 Xcode 並編譯。

---

## ✅ 成功檢查清單

編譯成功後，您應該看到：

```
┌─────────────────────────┐
│  🔴 Pomodoro Timer      │
│  Stay focused, get      │
│  things done            │
│                         │
│     ┌──────────┐        │
│     │  25:00   │        │
│     │  FOCUS   │        │
│     │  TIME    │        │
│     └──────────┘        │
│                         │
│   ⟲    ▶️    ○         │
│  Reset Play             │
└─────────────────────────┘
```

**測試功能：**
- [ ] 點擊 Play → 計時器開始倒數
- [ ] 時間顯示更新（24:59, 24:58...）
- [ ] 進度環開始填充（紅色）
- [ ] 點擊 Pause → 計時器暫停
- [ ] 點擊 Play（繼續）→ 計時器恢復
- [ ] 點擊 Reset → 回到 25:00

---

## 📚 相關文件

- **完整說明**：`/Users/wenhsu/Documents/wenyen/tomato_clock/TomatoClock/QUICK_START.md`
- **架構文件**：`/Users/wenhsu/Documents/wenyen/tomato_clock/TomatoClock/ARCHITECTURE.md`
- **MVP 總結**：`/Users/wenhsu/Documents/wenyen/tomato_clock/TomatoClock/MVP_SUMMARY.md`

---

## 🎯 預期編譯時間

- 第一次編譯：約 30-60 秒
- 後續編譯：約 5-10 秒

---

## 🎉 完成！

按照這些步驟，您的 Tomato Clock App 就可以執行了！

如果遇到任何問題，請參考錯誤訊息並使用上方的疑難排解指南。

Good luck! 🍅⏱️

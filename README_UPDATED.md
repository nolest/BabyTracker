# BabyTracker2 iOS 應用項目說明文檔

## 項目概述

BabyTracker2 是一款專為父母設計的嬰兒活動追蹤應用，使用 SwiftUI 開發，支援 iOS 14 及以上版本。應用提供全面的嬰兒日常活動記錄、統計分析、智能排程和 AI 輔助功能，幫助父母更好地了解和照顧寶寶的成長發展。

## 技術架構

- **開發框架**：SwiftUI
- **最低支援版本**：iOS 14+
- **數據存儲**：CoreData
- **AI 集成**：Deepseek API
- **本地化**：支持繁體中文、簡體中文和英語
- **設計風格**：使用飽和度較低的柔和顏色
- **依賴管理**：使用 Bundler 管理的 CocoaPods

## 項目結構

```
BabyTracker2/
├── BabyTracker2App.swift        # 應用入口文件
├── ContentView.swift           # 主內容視圖
├── Info.plist                  # 應用配置文件
├── Views/                      # 視圖層
│   ├── HomeView.swift          # 主頁視圖
│   ├── RecordView.swift        # 記錄視圖
│   ├── StatisticsView.swift    # 統計視圖 (圖表功能暫時禁用)
│   ├── SettingsView.swift      # 設置視圖
│   ├── AIAnalysisView.swift    # AI 分析視圖
│   ├── SmartScheduleView.swift # 智能排程視圖
│   └── BabySelectorView.swift  # 寶寶選擇器視圖
├── ViewModels/                 # 視圖模型層
├── Models/                     # 模型層
│   └── AppSettings.swift       # 應用設置模型
├── Services/                   # 服務層
│   └── DeepseekService.swift   # Deepseek API 服務
├── Utilities/                  # 工具類
│   └── LocalizationService.swift # 本地化服務
├── CoreData/                   # CoreData 相關
│   ├── DataController.swift    # 數據控制器
│   └── BabyTracker2.xcdatamodeld # CoreData 模型
└── Resources/                  # 資源文件
    ├── Assets.xcassets/        # 圖片資源
    │   ├── AppIcon.appiconset/ # 應用圖標
    │   └── Colors/             # 顏色資源
    └── Localization/           # 本地化資源
        ├── en.lproj/           # 英語
        ├── zh-Hant.lproj/      # 繁體中文
        └── zh-Hans.lproj/      # 簡體中文
```

## 依賴管理

項目使用 Bundler 管理的 CocoaPods 進行依賴管理，主要依賴包括：

- **Alamofire 5.4.0**: 用於網絡請求，特別是與 Deepseek API 的通信
- **KeychainSwift 19.0.0**: 用於安全存儲 API 密鑰

**注意**: Charts 依賴已暫時禁用，統計圖表功能將在未來版本中啟用。

## 安裝與運行

1. **安裝 Bundler**:
   ```
   gem install bundler
   ```

2. **安裝 CocoaPods**:
   ```
   bundle install
   ```

3. **安裝依賴**:
   ```
   bundle exec pod install
   ```

4. **打開項目**:
   使用 Xcode 打開生成的 `.xcworkspace` 文件，而不是 `.xcodeproj` 文件。

5. **清理項目**:
   在 Xcode 中選擇 Product > Clean Build Folder，然後編譯運行。

## 核心功能模組

### 1. 主頁（HomeView）

主頁提供寶寶當日活動的概覽，包括：
- 寶寶基本信息顯示
- 最近活動記錄摘要
- 今日統計數據
- 快速記錄按鈕
- 智能排程入口

### 2. 記錄功能（RecordView）

提供多種活動記錄類型，每種類型都有專門的表單：
- 餵食記錄（母乳、奶瓶、配方奶、固體食物）
- 尿布更換記錄
- 睡眠記錄
- 成長記錄（體重、身高、頭圍）
- 里程碑記錄
- 快樂時刻記錄
- 自定義記錄

每種記錄類型都支持計時器、備註和詳細參數設置。

### 3. 統計功能（StatisticsView）

提供各類活動的數據摘要和統計信息：
- 餵食統計（類型分佈、時間趨勢）
- 尿布統計（類型分佈、頻率趨勢）
- 睡眠統計（時長趨勢、質量分佈）
- 成長統計（體重、身高、頭圍趨勢）
- 支持按日、週、月查看數據
- AI 分析按鈕，提供深度洞察

**注意**: 圖表可視化功能暫時禁用，將在未來版本中啟用。

### 4. 設置功能（SettingsView）

提供應用配置和寶寶管理：
- 寶寶信息管理（添加、編輯、刪除）
- 語言設置（英語、繁體中文、簡體中文）
- 主題設置（淺色/深色模式）
- AI 功能開關
- 關於、隱私政策和使用條款

### 5. AI 分析功能（AIAnalysisView）

利用 Deepseek API 提供智能分析：
- 睡眠模式深度分析
- 餵食習慣分析
- 成長數據分析
- 綜合建議生成

### 6. 智能排程功能（SmartScheduleView）

基於歷史數據和 AI 分析生成智能日程：
- 根據寶寶活動模式生成每日最佳排程
- 提供餵食、睡眠、玩耍等活動的建議時間
- 支持自定義日期查看排程
- 顯示每項活動的詳細時間和持續時間

## 數據模型設計

使用 CoreData 進行數據持久化，主要實體包括：

1. **Baby**：寶寶基本信息
   - 姓名、出生日期、性別、照片等

2. **Activity**：基礎活動記錄
   - 類型、開始時間、結束時間、持續時間、備註等

3. **FeedingActivity**：餵食活動
   - 餵食類型、數量、單位、左右乳持續時間等

4. **DiaperActivity**：尿布活動
   - 尿布類型、狀態等

5. **SleepActivity**：睡眠活動
   - 睡眠質量、環境等

6. **GrowthRecord**：成長記錄
   - 體重、身高、頭圍等

7. **Milestone**：里程碑記錄
   - 標題、類別、描述等

8. **HappyMoment**：快樂時刻記錄
   - 標題、描述、照片等

## Deepseek API 集成

應用集成了 Deepseek API 以提供 AI 分析功能：

- **API Key 管理**：使用多個 API Key 並根據設備 ID 哈希值分配
- **請求頻率限制**：深度分析每小時最多 10 次，每天最多 30 次
- **數據匿名化**：僅發送匿名化數據進行分析
- **智能緩存**：減少重複請求
- **離線功能保障**：AI 功能不影響其他基本功能

## 本地化支持

應用完全支持三種語言：

- 英語 (en)
- 繁體中文 (zh-Hant)
- 簡體中文 (zh-Hans)

所有用戶界面文本、錯誤消息和 AI 分析結果都支持本地化。

## 已知問題與解決方案

1. **Charts 庫兼容性問題**：
   - 問題：Charts 庫與當前 Swift 版本存在兼容性問題
   - 臨時解決方案：暫時禁用圖表功能，使用文本摘要替代
   - 長期解決方案：未來版本將使用 Swift Package Manager 集成 DGCharts

2. **CoreData 模型繼承關係**：
   - 問題：子實體重複定義父實體的關係屬性
   - 解決方案：已修正模型，移除重複的關係定義

3. **項目結構重命名**：
   - 問題：從 BabyTracker 重命名為 BabyTracker2 可能導致引用問題
   - 解決方案：已更新所有引用，確保項目結構一致

## 未來擴展方向

1. **恢復圖表功能**：使用 Swift Package Manager 集成 DGCharts
2. **雲端同步**：添加 iCloud 或其他雲服務同步功能
3. **社交分享**：添加分享里程碑和快樂時刻的功能
4. **健康數據集成**：與 Apple Health 集成
5. **多設備支持**：開發 iPad 和 Apple Watch 版本
6. **更多 AI 功能**：擴展 AI 分析和預測能力

## 總結

BabyTracker2 是一款功能全面、設計精美的嬰兒活動追蹤應用，結合了現代 UI 設計、本地數據管理和先進的 AI 分析功能。應用使用 SwiftUI 開發，確保了良好的性能和用戶體驗，同時支持多語言環境，滿足不同用戶的需求。

通過 BabyTracker2，父母可以輕鬆記錄和分析寶寶的日常活動，獲取專業的 AI 建議，並根據智能排程更好地安排寶寶的日常生活，從而提供更科學、更有效的育兒支持。

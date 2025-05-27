# 寶寶生活記錄專業版（Baby Tracker）- 完整項目結構描述

## 概述

本文檔是「寶寶生活記錄專業版（Baby Tracker）」iOS應用的唯一權威項目結構描述，遵循iOS應用開發最佳實踐，採用MVVM架構設計模式和依賴注入原則。

## 完整目錄結構

```
BabyTracker/
├── BabyTracker.xcodeproj/       # Xcode項目文件
├── BabyTracker/                 # 主應用目錄
│   ├── App/                     # 應用程序入口
│   │   ├── AppDelegate.swift    # 應用程序委託
│   │   └── SceneDelegate.swift  # 場景委託
│   │
│   ├── Models/                  # 數據模型
│   │   ├── ActivityType.swift   # 活動類型枚舉
│   │   ├── FeedingType.swift    # 餵食類型枚舉
│   │   ├── SleepRecord.swift    # 睡眠記錄模型
│   │   ├── Activity.swift       # 活動記錄模型
│   │   ├── FeedingRecord.swift  # 餵食記錄模型
│   │   ├── EnvironmentFactors.swift  # 環境因素模型
│   │   ├── SleepInterruption.swift   # 睡眠中斷模型
│   │   ├── ActivityRecord.swift      # 活動記錄（用於分析）模型
│   │   ├── Baby.swift           # 寶寶信息模型
│   │   └── Growth.swift         # 成長記錄模型
│   │
│   ├── Repositories/            # 數據倉庫
│   │   ├── SleepRecordRepository.swift  # 睡眠記錄倉庫
│   │   ├── ActivityRepository.swift     # 活動倉庫
│   │   ├── FeedingRepository.swift      # 餵食記錄倉庫
│   │   ├── BabyRepository.swift         # 寶寶信息倉庫
│   │   └── GrowthRepository.swift       # 成長記錄倉庫
│   │
│   ├── Services/                # 服務層
│   │   ├── AI/                  # AI分析服務
│   │   │   ├── AIEngine.swift           # AI引擎
│   │   │   ├── SleepPatternAnalyzer.swift  # 睡眠模式分析器
│   │   │   ├── RoutineAnalyzer.swift       # 作息模式分析器
│   │   │   └── PredictionEngine.swift      # 預測引擎
│   │   │
│   │   ├── Cloud/               # 雲端服務
│   │   │   ├── CloudAIService.swift        # 雲端AI服務
│   │   │   ├── DeepseekAPIClient.swift     # Deepseek API客戶端
│   │   │   ├── DataAnonymizer.swift        # 數據匿名化處理
│   │   │   └── SyncService.swift           # 數據同步服務
│   │   │
│   │   ├── Settings/            # 設置服務
│   │   │   ├── UserSettings.swift          # 用戶設置
│   │   │   ├── NetworkMonitor.swift        # 網絡狀態監控
│   │   │   └── NotificationService.swift   # 通知服務
│   │   │
│   │   └── Core/                # 核心服務
│   │       ├── DataMigrationService.swift  # 數據遷移服務
│   │       └── BackupService.swift         # 備份服務
│   │
│   ├── Security/                # 安全相關
│   │   ├── APIKeyManager.swift  # API Key管理器
│   │   ├── DeviceIdentifier.swift  # 設備標識工具
│   │   └── UsageLimiter.swift   # 使用限制器
│   │
│   ├── Utils/                   # 工具類
│   │   ├── Extensions/          # 擴展
│   │   │   ├── DateExtensions.swift        # 日期擴展
│   │   │   ├── StringExtensions.swift      # 字符串擴展
│   │   │   ├── UIColorExtensions.swift     # 顏色擴展
│   │   │   └── UIViewExtensions.swift      # 視圖擴展
│   │   │
│   │   ├── Helpers/             # 輔助工具
│   │   │   ├── DependencyContainer.swift   # 依賴注入容器
│   │   │   ├── Constants.swift             # 常量定義
│   │   │   ├── Logger.swift                # 日誌工具
│   │   │   └── Formatters.swift            # 格式化工具
│   │   │
│   │   └── Errors/              # 錯誤類型
│   │       ├── CloudError.swift            # 雲端服務錯誤
│   │       ├── AnalysisError.swift         # 分析錯誤
│   │       ├── RepositoryError.swift       # 倉庫錯誤
│   │       └── NetworkError.swift          # 網絡錯誤
│   │
│   ├── UI/                      # 用戶界面
│   │   ├── Main/                # 主界面
│   │   │   ├── MainTabBarController.swift  # 主標籤欄控制器
│   │   │   ├── HomeViewController.swift    # 主頁視圖控制器
│   │   │   └── HomeViewModel.swift         # 主頁視圖模型
│   │   │
│   │   ├── Sleep/               # 睡眠相關界面
│   │   │   ├── SleepRecordViewController.swift  # 睡眠記錄視圖控制器
│   │   │   ├── SleepRecordViewModel.swift       # 睡眠記錄視圖模型
│   │   │   ├── SleepAnalysisViewController.swift  # 睡眠分析視圖控制器
│   │   │   └── SleepAnalysisViewModel.swift       # 睡眠分析視圖模型
│   │   │
│   │   ├── Feeding/             # 餵食相關界面
│   │   │   ├── FeedingRecordViewController.swift  # 餵食記錄視圖控制器
│   │   │   ├── FeedingRecordViewModel.swift       # 餵食記錄視圖模型
│   │   │   ├── FeedingAnalysisViewController.swift  # 餵食分析視圖控制器
│   │   │   └── FeedingAnalysisViewModel.swift       # 餵食分析視圖模型
│   │   │
│   │   ├── Activities/          # 活動相關界面
│   │   │   ├── ActivityRecordViewController.swift  # 活動記錄視圖控制器
│   │   │   ├── ActivityRecordViewModel.swift       # 活動記錄視圖模型
│   │   │   ├── ActivityAnalysisViewController.swift  # 活動分析視圖控制器
│   │   │   └── ActivityAnalysisViewModel.swift       # 活動分析視圖模型
│   │   │
│   │   ├── Analysis/            # 分析相關界面
│   │   │   ├── AnalysisDashboardViewController.swift  # 分析儀表板視圖控制器
│   │   │   ├── AnalysisDashboardViewModel.swift       # 分析儀表板視圖模型
│   │   │   ├── PredictionViewController.swift         # 預測視圖控制器
│   │   │   └── PredictionViewModel.swift              # 預測視圖模型
│   │   │
│   │   ├── Settings/            # 設置相關界面
│   │   │   ├── SettingsViewController.swift           # 設置視圖控制器
│   │   │   ├── SettingsViewModel.swift                # 設置視圖模型
│   │   │   ├── CloudSettingsViewController.swift      # 雲端設置視圖控制器
│   │   │   └── CloudSettingsViewModel.swift           # 雲端設置視圖模型
│   │   │
│   │   ├── Growth/              # 成長相關界面
│   │   │   ├── GrowthRecordViewController.swift       # 成長記錄視圖控制器
│   │   │   ├── GrowthRecordViewModel.swift            # 成長記錄視圖模型
│   │   │   ├── GrowthChartViewController.swift        # 成長圖表視圖控制器
│   │   │   └── GrowthChartViewModel.swift             # 成長圖表視圖模型
│   │   │
│   │   └── Common/              # 通用UI組件
│   │       ├── CustomButton.swift                     # 自定義按鈕
│   │       ├── CustomTextField.swift                  # 自定義文本輸入框
│   │       ├── CustomAlert.swift                      # 自定義警告框
│   │       ├── LoadingIndicator.swift                 # 加載指示器
│   │       ├── ChartView.swift                        # 圖表視圖
│   │       └── DatePickerView.swift                   # 日期選擇器視圖
│   │
│   └── Resources/               # 資源文件
│       ├── Assets.xcassets/     # 圖像資源
│       ├── Localizable.strings  # 本地化字符串
│       ├── Info.plist           # 應用信息配置
│       └── LaunchScreen.storyboard  # 啟動屏幕
│
├── BabyTrackerTests/            # 單元測試
│   ├── Models/                  # 模型測試
│   ├── Repositories/            # 倉庫測試
│   ├── Services/                # 服務測試
│   └── Utils/                   # 工具測試
│
└── BabyTrackerUITests/          # UI測試
    ├── Main/                    # 主界面測試
    ├── Sleep/                   # 睡眠界面測試
    ├── Feeding/                 # 餵食界面測試
    └── Activities/              # 活動界面測試
```

## 文件實現狀態

以下是所有Swift代碼文件的實現狀態：

### 已實現的文件

#### App目錄
- ✅ `AppDelegate.swift`
- ✅ `SceneDelegate.swift`

#### Models目錄
- ✅ `ActivityType.swift`
- ✅ `FeedingType.swift`
- ✅ `SleepRecord.swift`
- ✅ `Activity.swift`
- ✅ `FeedingRecord.swift`
- ✅ `EnvironmentFactors.swift`
- ✅ `SleepInterruption.swift`
- ✅ `ActivityRecord.swift`

#### Repositories目錄
- ✅ `SleepRecordRepository.swift`
- ✅ `ActivityRepository.swift`
- ✅ `FeedingRepository.swift`

#### Services/AI目錄
- ✅ `AIEngine.swift`
- ✅ `SleepPatternAnalyzer.swift`
- ✅ `RoutineAnalyzer.swift`
- ✅ `PredictionEngine.swift`

#### Services/Cloud目錄
- ✅ `CloudAIService.swift`
- ✅ `DeepseekAPIClient.swift`
- ✅ `DataAnonymizer.swift`

#### Services/Settings目錄
- ✅ `UserSettings.swift`
- ✅ `NetworkMonitor.swift`

#### Security目錄
- ✅ `APIKeyManager.swift`

#### Utils/Errors目錄
- ✅ `CloudError.swift`
- ✅ `AnalysisError.swift`

#### Utils/Helpers目錄
- ✅ `DependencyContainer.swift`

### 待實現的文件

#### Models目錄
- ❌ `Baby.swift`
- ❌ `Growth.swift`

#### Repositories目錄
- ❌ `BabyRepository.swift`
- ❌ `GrowthRepository.swift`

#### Services/Cloud目錄
- ❌ `SyncService.swift`

#### Services/Settings目錄
- ❌ `NotificationService.swift`

#### Services/Core目錄
- ❌ `DataMigrationService.swift`
- ❌ `BackupService.swift`

#### Security目錄
- ❌ `DeviceIdentifier.swift`
- ❌ `UsageLimiter.swift`

#### Utils/Extensions目錄
- ❌ `DateExtensions.swift`
- ❌ `StringExtensions.swift`
- ❌ `UIColorExtensions.swift`
- ❌ `UIViewExtensions.swift`

#### Utils/Helpers目錄
- ❌ `Constants.swift`
- ❌ `Logger.swift`
- ❌ `Formatters.swift`

#### Utils/Errors目錄
- ❌ `RepositoryError.swift`
- ❌ `NetworkError.swift`

#### UI目錄（所有UI相關文件）
- ❌ 所有UI目錄下的文件尚未實現

#### Resources目錄
- ❌ 所有Resources目錄下的文件尚未實現

#### 測試目錄
- ❌ 所有測試目錄下的文件尚未實現

## 核心依賴關係

### 依賴注入容器 (DependencyContainer)

`DependencyContainer.swift` 是整個應用的核心，負責管理所有服務和倉庫的依賴關係。它實現了單例模式，並提供了以下依賴：

1. **倉庫依賴**
   - sleepRecordRepository: SleepRecordRepositoryProtocol
   - activityRepository: ActivityRepositoryProtocol
   - feedingRepository: FeedingRepositoryProtocol

2. **分析服務依賴**
   - sleepPatternAnalyzer: SleepPatternAnalyzer
   - routineAnalyzer: RoutineAnalyzer
   - predictionEngine: PredictionEngine

3. **網絡與設置依賴**
   - networkMonitor: NetworkMonitor
   - userSettings: UserSettings

4. **API與安全依賴**
   - apiKeyManager: APIKeyManager
   - dataAnonymizer: DataAnonymizer
   - deepseekAPIClient: DeepseekAPIClient

5. **雲端服務依賴**
   - cloudAIService: CloudAIService

6. **AI引擎依賴**
   - aiEngine: AIEngine

### AI引擎 (AIEngine)

`AIEngine.swift` 是AI分析功能的核心，實現了混合模式（本地+雲端）的AI分析。它依賴於：

1. sleepPatternAnalyzer: 用於本地睡眠模式分析
2. routineAnalyzer: 用於本地作息模式分析
3. predictionEngine: 用於本地預測
4. cloudAIService: 用於雲端AI分析
5. networkMonitor: 用於檢查網絡狀態
6. userSettings: 用於檢查用戶設置

### 雲端服務 (CloudAIService)

`CloudAIService.swift` 負責與Deepseek API的通信，依賴於：

1. networkMonitor: 用於檢查網絡狀態
2. userSettings: 用於檢查用戶設置
3. dataAnonymizer: 用於數據匿名化
4. apiClient: 用於API通信

## 接口定義

### Repository接口

所有倉庫都實現了對應的協議接口：

1. **SleepRecordRepositoryProtocol**
   ```swift
   protocol SleepRecordRepositoryProtocol {
       func getSleepRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[SleepRecord], Error>
       func saveSleepRecord(_ record: SleepRecord) async -> Result<Void, Error>
       func deleteSleepRecord(id: String) async -> Result<Void, Error>
   }
   ```

2. **ActivityRepositoryProtocol**
   ```swift
   protocol ActivityRepositoryProtocol {
       func getActivities(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[Activity], Error>
       func saveActivity(_ activity: Activity) async -> Result<Void, Error>
       func deleteActivity(id: String) async -> Result<Void, Error>
   }
   ```

3. **FeedingRepositoryProtocol**
   ```swift
   protocol FeedingRepositoryProtocol {
       func getFeedingRecords(babyId: String, dateRange: ClosedRange<Date>) async -> Result<[FeedingRecord], Error>
       func saveFeedingRecord(_ record: FeedingRecord) async -> Result<Void, Error>
       func deleteFeedingRecord(id: String) async -> Result<Void, Error>
   }
   ```

### 分析結果模型

所有分析結果都使用統一的模型結構：

1. **SleepPatternResult**
   - 睡眠模式分析結果，包含模式、建議和質量分數

2. **RoutineAnalysisResult**
   - 作息分析結果，包含模式、建議和規律性分數

3. **PredictionResult**
   - 預測結果，包含睡眠預測、餵食預測和置信度分數

### 錯誤類型

應用定義了清晰的錯誤類型層次：

1. **AnalysisError**
   - 本地分析錯誤，如數據不足、無效的日期範圍等

2. **CloudError**
   - 雲端服務錯誤，如網絡錯誤、API密鑰無效等

3. **DeepseekAPIClient.APIError**
   - API通信錯誤，如無效URL、服務器錯誤等

## 實現優先級

根據應用的核心功能和依賴關係，文件實現優先級如下：

### 高優先級（已全部實現）

1. 核心數據模型（Models目錄下的基本文件）
2. 錯誤類型定義（Utils/Errors目錄下的基本文件）
3. Repository接口與實現（Repositories目錄下的基本文件）
4. 依賴注入容器（Utils/Helpers/DependencyContainer.swift）
5. 基本應用文件（App目錄下的所有文件）
6. 核心服務（Services目錄下的AI、Cloud、Settings子目錄中的基本文件）
7. 安全相關代碼（Security目錄下的基本文件）

### 中優先級（待實現）

1. 擴展（Utils/Extensions目錄下的所有文件）
2. 主要UI控制器和視圖模型（UI/Main目錄下的所有文件）
3. 分析相關UI（UI/Analysis目錄下的所有文件）
4. 設置相關UI（UI/Settings目錄下的所有文件）

### 低優先級（待實現）

1. 其他UI控制器和視圖模型（UI/Sleep、UI/Feeding、UI/Activities目錄下的所有文件）
2. 輔助工具和常量（Utils/Helpers/Constants.swift等）
3. 測試文件（BabyTrackerTests和BabyTrackerUITests目錄下的所有文件）

## 導入Xcode指南

要將這些文件導入Xcode工程，請按照以下步驟操作：

1. 創建新的Xcode項目，選擇iOS應用模板
2. 在Xcode中創建上述目錄結構
3. 將所有已實現的Swift文件複製到對應目錄
4. 確保項目設置中的最低部署目標為iOS 15.0
5. 在Info.plist中添加必要的權限描述（如網絡使用權限）
6. 編譯項目，解決可能的依賴問題

## 後續開發建議

1. 按照中優先級列表，優先實現UI層的基本框架
2. 實現本地數據持久化（如CoreData）
3. 完成剩餘的服務和工具類
4. 實現UI層的詳細功能
5. 添加單元測試和UI測試
6. 實現本地化支持多語言

## 結論

本文檔提供了「寶寶生活記錄專業版（Baby Tracker）」iOS應用的完整、唯一且權威的項目結構描述。它詳細列出了所有目錄和文件，明確標示了已實現和待實現的文件，並提供了核心依賴關係、接口定義和實現優先級的說明。按照本文檔進行開發，可以確保項目結構清晰、代碼質量高、功能完整。

# 寶寶生活記錄專業版（Baby Tracker）- Xcode工程推薦結構與代碼文件清單

根據iOS應用開發最佳實踐和前述分析，以下是「寶寶生活記錄專業版（Baby Tracker）」應用的推薦Xcode工程結構和所有應有的Swift代碼文件清單。

## 推薦工程結構

```
BabyTracker/
├── BabyTracker/
│   ├── App/
│   ├── Models/
│   ├── Repositories/
│   ├── Services/
│   │   ├── AI/
│   │   ├── Cloud/
│   │   └── Settings/
│   ├── Security/
│   ├── Utils/
│   │   ├── Extensions/
│   │   ├── Helpers/
│   │   └── Errors/
│   ├── UI/
│   │   ├── Main/
│   │   ├── Sleep/
│   │   ├── Feeding/
│   │   ├── Activities/
│   │   ├── Analysis/
│   │   └── Settings/
│   └── Resources/
```

## 所有應有的Swift代碼文件清單

### 1. App目錄

- `AppDelegate.swift` - 應用程序委託
- `SceneDelegate.swift` - 場景委託

### 2. Models目錄

- `ActivityType.swift` - 活動類型枚舉
- `FeedingType.swift` - 餵食類型枚舉
- `SleepRecord.swift` - 睡眠記錄模型
- `Activity.swift` - 活動記錄模型
- `FeedingRecord.swift` - 餵食記錄模型
- `EnvironmentFactors.swift` - 環境因素模型
- `SleepInterruption.swift` - 睡眠中斷模型
- `ActivityRecord.swift` - 活動記錄（用於分析）模型

### 3. Repositories目錄

- `SleepRecordRepository.swift` - 睡眠記錄倉庫
- `ActivityRepository.swift` - 活動倉庫
- `FeedingRepository.swift` - 餵食記錄倉庫

### 4. Services/AI目錄

- `AIEngine.swift` - AI引擎
- `SleepPatternAnalyzer.swift` - 睡眠模式分析器
- `RoutineAnalyzer.swift` - 作息模式分析器
- `PredictionEngine.swift` - 預測引擎

### 5. Services/Cloud目錄

- `CloudAIService.swift` - 雲端AI服務
- `DeepseekAPIClient.swift` - Deepseek API客戶端
- `DataAnonymizer.swift` - 數據匿名化處理

### 6. Services/Settings目錄

- `UserSettings.swift` - 用戶設置
- `NetworkMonitor.swift` - 網絡狀態監控

### 7. Security目錄

- `APIKeyManager.swift` - API Key管理器
- `DeviceIdentifier.swift` - 設備標識工具
- `UsageLimiter.swift` - 使用限制器

### 8. Utils/Errors目錄

- `CloudError.swift` - 雲端服務錯誤
- `AnalysisError.swift` - 分析錯誤

### 9. Utils/Extensions目錄

- `DateExtensions.swift` - 日期擴展
- `StringExtensions.swift` - 字符串擴展
- `UIColorExtensions.swift` - 顏色擴展

### 10. Utils/Helpers目錄

- `DependencyContainer.swift` - 依賴注入容器
- `Constants.swift` - 常量定義

### 11. UI/Main目錄

- `MainTabBarController.swift` - 主標籤欄控制器
- `HomeViewController.swift` - 主頁視圖控制器
- `HomeViewModel.swift` - 主頁視圖模型

### 12. UI/Sleep目錄

- `SleepRecordViewController.swift` - 睡眠記錄視圖控制器
- `SleepRecordViewModel.swift` - 睡眠記錄視圖模型
- `SleepAnalysisViewController.swift` - 睡眠分析視圖控制器
- `SleepAnalysisViewModel.swift` - 睡眠分析視圖模型

### 13. UI/Feeding目錄

- `FeedingRecordViewController.swift` - 餵食記錄視圖控制器
- `FeedingRecordViewModel.swift` - 餵食記錄視圖模型
- `FeedingAnalysisViewController.swift` - 餵食分析視圖控制器
- `FeedingAnalysisViewModel.swift` - 餵食分析視圖模型

### 14. UI/Activities目錄

- `ActivityRecordViewController.swift` - 活動記錄視圖控制器
- `ActivityRecordViewModel.swift` - 活動記錄視圖模型
- `ActivityAnalysisViewController.swift` - 活動分析視圖控制器
- `ActivityAnalysisViewModel.swift` - 活動分析視圖模型

### 15. UI/Analysis目錄

- `AnalysisDashboardViewController.swift` - 分析儀表板視圖控制器
- `AnalysisDashboardViewModel.swift` - 分析儀表板視圖模型
- `PredictionViewController.swift` - 預測視圖控制器
- `PredictionViewModel.swift` - 預測視圖模型

### 16. UI/Settings目錄

- `SettingsViewController.swift` - 設置視圖控制器
- `SettingsViewModel.swift` - 設置視圖模型
- `CloudSettingsViewController.swift` - 雲端設置視圖控制器
- `CloudSettingsViewModel.swift` - 雲端設置視圖模型

## 優先級排序

根據應用的核心功能和依賴關係，以下是代碼文件的優先級排序：

### 高優先級（必須實現）

1. 核心數據模型（Models目錄下的所有文件）
2. 錯誤類型定義（Utils/Errors目錄下的所有文件）
3. Repository接口與實現（Repositories目錄下的所有文件）
4. 依賴注入容器（Utils/Helpers/DependencyContainer.swift）
5. 基本應用文件（App目錄下的所有文件）
6. 核心服務（Services目錄下的AI、Cloud、Settings子目錄中的所有文件）
7. 安全相關代碼（Security目錄下的所有文件）

### 中優先級（建議實現）

1. 擴展（Utils/Extensions目錄下的所有文件）
2. 主要UI控制器和視圖模型（UI/Main目錄下的所有文件）
3. 分析相關UI（UI/Analysis目錄下的所有文件）
4. 設置相關UI（UI/Settings目錄下的所有文件）

### 低優先級（可選實現）

1. 其他UI控制器和視圖模型（UI/Sleep、UI/Feeding、UI/Activities目錄下的所有文件）
2. 輔助工具和常量（Utils/Helpers/Constants.swift）

## 注意事項

1. 所有文件應使用Swift 5語法
2. 所有公共API應有適當的文檔注釋
3. 所有類和結構體應有明確的職責和依賴關係
4. 所有UI相關代碼應支持iOS 15.0及以上版本
5. 所有代碼應遵循Swift命名規範和最佳實踐

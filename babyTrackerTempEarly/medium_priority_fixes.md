# 寶寶生活記錄專業版（Baby Tracker）- 中優先級整合改進

## 概述

本文檔詳細說明「寶寶生活記錄專業版（Baby Tracker）」iOS應用中第三階段與前兩階段整合的中優先級改進項目，包括統一數據轉換方式、優化可視化整合、添加分析設置界面和改進分析過程透明度等。

## 1. 統一數據轉換方式

### 問題描述

在整合驗證中發現，AI分析結果轉換為視圖模型的方式不夠統一，部分地方使用直接賦值，部分地方使用映射函數，導致代碼不一致且難以維護。

### 解決方案

#### 1.1 創建統一的映射協議

```swift
// 定義統一的映射協議
protocol DomainModelConvertible {
    associatedtype DomainModel
    
    func toDomain() -> DomainModel
}

protocol ViewModelConvertible {
    associatedtype ViewModel
    
    func toViewModel() -> ViewModel
}
```

#### 1.2 為所有模型實現映射協議

```swift
// 領域模型到視圖模型的轉換
extension SleepPatternAnalysisResult: ViewModelConvertible {
    typealias ViewModel = SleepPatternAnalysisViewModel
    
    func toViewModel() -> SleepPatternAnalysisViewModel {
        return SleepPatternAnalysisViewModel(
            id: self.id,
            babyId: self.babyId,
            analysisDate: self.analysisDate,
            sleepEfficiency: self.sleepEfficiency,
            sleepQualityScore: self.sleepQualityScore,
            averageSleepDuration: self.averageSleepDuration,
            sleepCycleCount: self.sleepCycleCount,
            environmentalFactors: self.environmentalFactors.map { $0.toViewModel() },
            recommendations: self.recommendations.map { $0.toViewModel() },
            analysisSource: self.analysisSource.toViewModel()
        )
    }
}

// 視圖模型到領域模型的轉換
extension SleepPatternAnalysisViewModel: DomainModelConvertible {
    typealias DomainModel = SleepPatternAnalysisResult
    
    func toDomain() -> SleepPatternAnalysisResult {
        return SleepPatternAnalysisResult(
            id: self.id,
            babyId: self.babyId,
            analysisDate: self.analysisDate,
            sleepEfficiency: self.sleepEfficiency,
            sleepQualityScore: self.sleepQualityScore,
            averageSleepDuration: self.averageSleepDuration,
            sleepCycleCount: self.sleepCycleCount,
            environmentalFactors: self.environmentalFactors.map { $0.toDomain() },
            recommendations: self.recommendations.map { $0.toDomain() },
            analysisSource: self.analysisSource.toDomain()
        )
    }
}
```

#### 1.3 在視圖模型中統一使用映射函數

```swift
// 修改前：直接賦值
func updateWithAnalysisResult(_ result: SleepPatternAnalysisResult) {
    self.sleepEfficiency = result.sleepEfficiency
    self.sleepQualityScore = result.sleepQualityScore
    self.averageSleepDuration = result.averageSleepDuration
    // 更多賦值...
}

// 修改後：使用映射函數
func updateWithAnalysisResult(_ result: SleepPatternAnalysisResult) {
    let viewModel = result.toViewModel()
    self.sleepEfficiency = viewModel.sleepEfficiency
    self.sleepQualityScore = viewModel.sleepQualityScore
    self.averageSleepDuration = viewModel.averageSleepDuration
    // 更多賦值...
}

// 更好的方式：完全使用映射函數
func updateWithAnalysisResult(_ result: SleepPatternAnalysisResult) {
    let viewModel = result.toViewModel()
    self.update(from: viewModel)
}

func update(from viewModel: SleepPatternAnalysisViewModel) {
    self.sleepEfficiency = viewModel.sleepEfficiency
    self.sleepQualityScore = viewModel.sleepQualityScore
    self.averageSleepDuration = viewModel.averageSleepDuration
    // 更多賦值...
}
```

## 2. 優化可視化整合

### 問題描述

AI分析結果的可視化未完全利用前兩階段設計的可視化組件，導致視覺風格不一致，且增加了維護成本。

### 解決方案

#### 2.1 重構可視化組件，提高復用性

```swift
// 定義通用的圖表數據協議
protocol ChartDataConvertible {
    func toBarChartData() -> BarChartData
    func toLineChartData() -> LineChartData
    func toPieChartData() -> PieChartData
}

// 為分析結果實現圖表數據協議
extension SleepPatternAnalysisResult: ChartDataConvertible {
    func toBarChartData() -> BarChartData {
        // 實現...
    }
    
    func toLineChartData() -> LineChartData {
        // 實現...
    }
    
    func toPieChartData() -> PieChartData {
        // 實現...
    }
}
```

#### 2.2 創建統一的可視化組件

```swift
// 統一的睡眠時長趨勢圖組件
struct SleepDurationTrendChart: View {
    let data: LineChartData
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LineChartView(data: data)
                .frame(height: 200)
                .padding(.vertical)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
}

// 統一的睡眠質量分布圖組件
struct SleepQualityDistributionChart: View {
    let data: PieChartData
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            PieChartView(data: data)
                .frame(height: 200)
                .padding(.vertical)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
}
```

#### 2.3 在分析結果頁面使用統一的可視化組件

```swift
// 修改前：直接在頁面中實現可視化
struct SleepAnalysisResultView: View {
    let result: SleepPatternAnalysisResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 直接實現的睡眠時長趨勢圖
                VStack(alignment: .leading) {
                    Text("睡眠時長趨勢")
                        .font(.headline)
                    
                    // 自定義實現的圖表
                    // ...
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // 更多直接實現的圖表...
            }
            .padding()
        }
    }
}

// 修改後：使用統一的可視化組件
struct SleepAnalysisResultView: View {
    let result: SleepPatternAnalysisResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 使用統一的睡眠時長趨勢圖組件
                SleepDurationTrendChart(
                    data: result.toLineChartData(),
                    title: "睡眠時長趨勢",
                    subtitle: "過去14天的睡眠時長變化"
                )
                
                // 使用統一的睡眠質量分布圖組件
                SleepQualityDistributionChart(
                    data: result.toPieChartData(),
                    title: "睡眠質量分布",
                    subtitle: "各睡眠質量級別的分布情況"
                )
                
                // 更多統一的可視化組件...
            }
            .padding()
        }
    }
}
```

## 3. 添加分析設置界面

### 問題描述

當前缺少AI分析相關的用戶設置界面，用戶無法自定義分析參數，降低了用戶控制力和個性化體驗。

### 解決方案

#### 3.1 設計分析設置模型

```swift
// 分析設置模型
struct AnalysisSettings: Codable, Equatable {
    // 通用設置
    var preferLocalAnalysis: Bool = false
    var analysisFrequency: AnalysisFrequency = .daily
    
    // 睡眠分析設置
    var sleepAnalysisSettings = SleepAnalysisSettings()
    
    // 作息分析設置
    var routineAnalysisSettings = RoutineAnalysisSettings()
    
    // 預測設置
    var predictionSettings = PredictionSettings()
}

// 分析頻率
enum AnalysisFrequency: String, Codable, CaseIterable {
    case realTime = "real_time"
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    
    var displayName: String {
        switch self {
        case .realTime: return "即時分析"
        case .hourly: return "每小時分析"
        case .daily: return "每日分析"
        case .weekly: return "每週分析"
        }
    }
}

// 睡眠分析設置
struct SleepAnalysisSettings: Codable, Equatable {
    var analysisDepth: AnalysisDepth = .comprehensive
    var includeEnvironmentalFactors: Bool = true
    var historicalDataRange: TimeRange = .twoWeeks
}

// 分析深度
enum AnalysisDepth: String, Codable, CaseIterable {
    case basic = "basic"
    case standard = "standard"
    case comprehensive = "comprehensive"
    
    var displayName: String {
        switch self {
        case .basic: return "基本分析"
        case .standard: return "標準分析"
        case .comprehensive: return "全面分析"
        }
    }
}

// 時間範圍
enum TimeRange: String, Codable, CaseIterable {
    case oneWeek = "one_week"
    case twoWeeks = "two_weeks"
    case oneMonth = "one_month"
    case threeMonths = "three_months"
    
    var displayName: String {
        switch self {
        case .oneWeek: return "一週"
        case .twoWeeks: return "兩週"
        case .oneMonth: return "一個月"
        case .threeMonths: return "三個月"
        }
    }
    
    var days: Int {
        switch self {
        case .oneWeek: return 7
        case .twoWeeks: return 14
        case .oneMonth: return 30
        case .threeMonths: return 90
        }
    }
}
```

#### 3.2 實現設置存儲服務

```swift
// 設置存儲服務
class SettingsService {
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "analysis_settings"
    
    func getAnalysisSettings() -> AnalysisSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AnalysisSettings.self, from: data) else {
            return AnalysisSettings() // 返回默認設置
        }
        return settings
    }
    
    func saveAnalysisSettings(_ settings: AnalysisSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: settingsKey)
    }
}
```

#### 3.3 創建分析設置界面

```swift
// 分析設置視圖
struct AnalysisSettingsView: View {
    @StateObject private var viewModel = AnalysisSettingsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                // 通用設置
                Section(header: Text("通用設置")) {
                    Toggle("優先使用本地分析", isOn: $viewModel.settings.preferLocalAnalysis)
                    
                    Picker("分析頻率", selection: $viewModel.settings.analysisFrequency) {
                        ForEach(AnalysisFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                }
                
                // 睡眠分析設置
                Section(header: Text("睡眠分析設置")) {
                    Picker("分析深度", selection: $viewModel.settings.sleepAnalysisSettings.analysisDepth) {
                        ForEach(AnalysisDepth.allCases, id: \.self) { depth in
                            Text(depth.displayName).tag(depth)
                        }
                    }
                    
                    Toggle("包含環境因素分析", isOn: $viewModel.settings.sleepAnalysisSettings.includeEnvironmentalFactors)
                    
                    Picker("歷史數據範圍", selection: $viewModel.settings.sleepAnalysisSettings.historicalDataRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                }
                
                // 作息分析設置
                Section(header: Text("作息分析設置")) {
                    // 類似的設置項...
                }
                
                // 預測設置
                Section(header: Text("預測設置")) {
                    // 類似的設置項...
                }
            }
            .navigationTitle("分析設置")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    viewModel.saveSettings()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// 分析設置視圖模型
class AnalysisSettingsViewModel: ObservableObject {
    @Published var settings: AnalysisSettings
    private let settingsService = SettingsService()
    
    init() {
        self.settings = settingsService.getAnalysisSettings()
    }
    
    func saveSettings() {
        settingsService.saveAnalysisSettings(settings)
    }
}
```

#### 3.4 在主界面添加設置入口

```swift
// 在分析頁面添加設置入口
struct SleepAnalysisView: View {
    @ObservedObject var viewModel: SleepAnalysisViewModel
    @State private var showingSettings = false
    
    var body: some View {
        VStack {
            // 現有UI...
            
            // 添加設置按鈕
            HStack {
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color(.systemBackground))
                                .shadow(radius: 2)
                        )
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingSettings) {
            AnalysisSettingsView()
        }
    }
}
```

## 4. 改進分析過程透明度

### 問題描述

當前分析過程缺乏透明度，用戶無法了解分析進度和具體步驟，降低了用戶體驗和信任度。

### 解決方案

#### 4.1 設計分析進度模型

```swift
// 分析階段
enum AnalysisStage: String, CaseIterable {
    case dataLoading = "data_loading"
    case preprocessing = "preprocessing"
    case patternAnalysis = "pattern_analysis"
    case environmentalAnalysis = "environmental_analysis"
    case qualityEvaluation = "quality_evaluation"
    case recommendationGeneration = "recommendation_generation"
    case finalizing = "finalizing"
    
    var displayName: String {
        switch self {
        case .dataLoading: return "加載數據"
        case .preprocessing: return "數據預處理"
        case .patternAnalysis: return "模式分析"
        case .environmentalAnalysis: return "環境因素分析"
        case .qualityEvaluation: return "質量評估"
        case .recommendationGeneration: return "生成建議"
        case .finalizing: return "完成分析"
        }
    }
    
    var description: String {
        switch self {
        case .dataLoading: return "正在加載寶寶的睡眠記錄數據..."
        case .preprocessing: return "正在清理和準備數據進行分析..."
        case .patternAnalysis: return "正在識別睡眠模式和週期..."
        case .environmentalAnalysis: return "正在分析環境因素對睡眠的影響..."
        case .qualityEvaluation: return "正在評估整體睡眠質量..."
        case .recommendationGeneration: return "正在基於分析結果生成個性化建議..."
        case .finalizing: return "正在完成分析並準備結果..."
        }
    }
}

// 分析進度
struct AnalysisProgress {
    let stage: AnalysisStage
    let progress: Double // 0.0 - 1.0
    let message: String?
    
    init(stage: AnalysisStage, progress: Double, message: String? = nil) {
        self.stage = stage
        self.progress = progress
        self.message = message
    }
}
```

#### 4.2 在AIEngine中添加進度報告

```swift
// 修改AIEngine，添加進度報告
class AIEngine {
    // 進度報告回調
    var onProgressUpdate: ((AnalysisProgress) -> Void)?
    
    func analyzeSleepPattern(for babyId: UUID) -> AnyPublisher<SleepPatternAnalysisResult, AppError> {
        return Future<SleepPatternAnalysisResult, AppError> { [weak self] promise in
            // 報告進度：數據加載
            self?.onProgressUpdate?(AnalysisProgress(
                stage: .dataLoading,
                progress: 0.0
            ))
            
            // 加載數據...
            
            // 報告進度：數據加載完成
            self?.onProgressUpdate?(AnalysisProgress(
                stage: .dataLoading,
                progress: 1.0
            ))
            
            // 報告進度：數據預處理
            self?.onProgressUpdate?(AnalysisProgress(
                stage: .preprocessing,
                progress: 0.0
            ))
            
            // 預處理數據...
            
            // 報告進度：數據預處理完成
            self?.onProgressUpdate?(AnalysisProgress(
                stage: 
(Content truncated due to size limit. Use line ranges to read in chunks)
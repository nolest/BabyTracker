// visualization_integration.swift
// 寶寶生活記錄專業版（Baby Tracker）- 整合改進
// 可視化整合實現

import Foundation
import UIKit
import Charts

// MARK: - 圖表數據協議

/// 圖表數據協議，定義圖表數據的標準接口
protocol ChartDataProvider {
    /// 獲取圖表數據
    /// - Returns: 圖表數據
    func getChartData() -> Any
    
    /// 獲取圖表標題
    /// - Returns: 圖表標題
    func getChartTitle() -> String
    
    /// 獲取圖表描述
    /// - Returns: 圖表描述
    func getChartDescription() -> String?
}

// MARK: - 睡眠模式圖表數據提供者

/// 睡眠模式圖表數據提供者，提供睡眠模式分析結果的圖表數據
class SleepPatternChartDataProvider: ChartDataProvider {
    // MARK: - 屬性
    
    private let sleepPatternResult: SleepPatternResult
    
    // MARK: - 初始化
    
    /// 初始化睡眠模式圖表數據提供者
    /// - Parameter sleepPatternResult: 睡眠模式分析結果
    init(sleepPatternResult: SleepPatternResult) {
        self.sleepPatternResult = sleepPatternResult
    }
    
    // MARK: - ChartDataProvider 協議實現
    
    /// 獲取圖表數據
    /// - Returns: 圖表數據
    func getChartData() -> Any {
        // 創建睡眠質量分佈數據
        let entries = [
            PieChartDataEntry(value: Double(sleepPatternResult.sleepQualityScore), label: NSLocalizedString("睡眠質量", comment: "")),
            PieChartDataEntry(value: Double(sleepPatternResult.regularityScore), label: NSLocalizedString("規律性", comment: ""))
        ]
        
        // 創建數據集
        let dataSet = PieChartDataSet(entries: entries, label: NSLocalizedString("睡眠模式分析", comment: ""))
        dataSet.colors = [.systemBlue, .systemGreen]
        dataSet.valueTextColor = .black
        dataSet.valueFont = .systemFont(ofSize: 12)
        
        // 創建圖表數據
        let data = PieChartData(dataSet: dataSet)
        
        return data
    }
    
    /// 獲取圖表標題
    /// - Returns: 圖表標題
    func getChartTitle() -> String {
        return NSLocalizedString("睡眠模式分析", comment: "")
    }
    
    /// 獲取圖表描述
    /// - Returns: 圖表描述
    func getChartDescription() -> String? {
        let patternTypeString: String
        switch sleepPatternResult.sleepPatternType {
        case .highlyRegular:
            patternTypeString = NSLocalizedString("高度規律", comment: "")
        case .moderatelyRegular:
            patternTypeString = NSLocalizedString("中度規律", comment: "")
        case .irregular:
            patternTypeString = NSLocalizedString("不規律", comment: "")
        case .evolving:
            patternTypeString = NSLocalizedString("發展中", comment: "")
        case .transitioning:
            patternTypeString = NSLocalizedString("過渡期", comment: "")
        case .insufficient:
            patternTypeString = NSLocalizedString("數據不足", comment: "")
        }
        
        return String(format: NSLocalizedString("睡眠模式類型：%@\n平均睡眠時長：%.1f小時\n分析來源：%@", comment: ""),
                      patternTypeString,
                      sleepPatternResult.averageSleepDuration / 3600,
                      sleepPatternResult.isCloudAnalysis ? NSLocalizedString("雲端分析", comment: "") : NSLocalizedString("本地分析", comment: ""))
    }
}

// MARK: - 作息分析圖表數據提供者

/// 作息分析圖表數據提供者，提供作息分析結果的圖表數據
class RoutineAnalysisChartDataProvider: ChartDataProvider {
    // MARK: - 屬性
    
    private let routineAnalysisResult: RoutineAnalysisResult
    
    // MARK: - 初始化
    
    /// 初始化作息分析圖表數據提供者
    /// - Parameter routineAnalysisResult: 作息分析結果
    init(routineAnalysisResult: RoutineAnalysisResult) {
        self.routineAnalysisResult = routineAnalysisResult
    }
    
    // MARK: - ChartDataProvider 協議實現
    
    /// 獲取圖表數據
    /// - Returns: 圖表數據
    func getChartData() -> Any {
        // 創建活動分佈數據
        let entries = routineAnalysisResult.activityDistribution.map { distribution -> PieChartDataEntry in
            return PieChartDataEntry(
                value: distribution.percentage * 100,
                label: getActivityTypeLabel(distribution.activityType)
            )
        }
        
        // 創建數據集
        let dataSet = PieChartDataSet(entries: entries, label: NSLocalizedString("活動分佈", comment: ""))
        dataSet.colors = ChartColorPalette.shared.getPieChartColors(count: entries.count)
        dataSet.valueTextColor = .black
        dataSet.valueFont = .systemFont(ofSize: 12)
        
        // 創建圖表數據
        let data = PieChartData(dataSet: dataSet)
        
        return data
    }
    
    /// 獲取圖表標題
    /// - Returns: 圖表標題
    func getChartTitle() -> String {
        return NSLocalizedString("作息分析", comment: "")
    }
    
    /// 獲取圖表描述
    /// - Returns: 圖表描述
    func getChartDescription() -> String? {
        let trendString: String
        switch routineAnalysisResult.trend {
        case .improving:
            trendString = NSLocalizedString("改善中", comment: "")
        case .stable:
            trendString = NSLocalizedString("穩定", comment: "")
        case .declining:
            trendString = NSLocalizedString("下降", comment: "")
        case .fluctuating:
            trendString = NSLocalizedString("波動", comment: "")
        case .insufficient:
            trendString = NSLocalizedString("數據不足", comment: "")
        }
        
        return String(format: NSLocalizedString("規律性評分：%d\n作息趨勢：%@\n分析來源：%@", comment: ""),
                      routineAnalysisResult.regularityScore,
                      trendString,
                      routineAnalysisResult.isCloudAnalysis ? NSLocalizedString("雲端分析", comment: "") : NSLocalizedString("本地分析", comment: ""))
    }
    
    /// 獲取活動類型標籤
    /// - Parameter activityType: 活動類型
    /// - Returns: 活動類型標籤
    private func getActivityTypeLabel(_ activityType: String) -> String {
        switch activityType.lowercased() {
        case "sleep":
            return NSLocalizedString("睡眠", comment: "")
        case "feeding":
            return NSLocalizedString("餵食", comment: "")
        case "diaper":
            return NSLocalizedString("換尿布", comment: "")
        case "play":
            return NSLocalizedString("玩耍", comment: "")
        case "bath":
            return NSLocalizedString("洗澡", comment: "")
        default:
            return activityType
        }
    }
}

// MARK: - 預測圖表數據提供者

/// 預測圖表數據提供者，提供預測結果的圖表數據
class PredictionChartDataProvider: ChartDataProvider {
    // MARK: - 屬性
    
    private let predictionResult: PredictionResult
    
    // MARK: - 初始化
    
    /// 初始化預測圖表數據提供者
    /// - Parameter predictionResult: 預測結果
    init(predictionResult: PredictionResult) {
        self.predictionResult = predictionResult
    }
    
    // MARK: - ChartDataProvider 協議實現
    
    /// 獲取圖表數據
    /// - Returns: 圖表數據
    func getChartData() -> Any {
        guard let nextSleep = predictionResult.nextSleep else {
            // 如果沒有下次睡眠預測，返回空數據
            return BarChartData()
        }
        
        // 創建預測時間範圍數據
        let earliestHour = Calendar.current.component(.hour, from: nextSleep.earliestStartTime)
        let earliestMinute = Calendar.current.component(.minute, from: nextSleep.earliestStartTime)
        let latestHour = Calendar.current.component(.hour, from: nextSleep.latestStartTime)
        let latestMinute = Calendar.current.component(.minute, from: nextSleep.latestStartTime)
        
        let earliestValue = Double(earliestHour) + Double(earliestMinute) / 60.0
        let latestValue = Double(latestHour) + Double(latestMinute) / 60.0
        
        // 創建條形圖數據
        let entries = [
            BarChartDataEntry(x: 0, y: earliestValue, data: NSLocalizedString("最早開始時間", comment: "")),
            BarChartDataEntry(x: 1, y: latestValue, data: NSLocalizedString("最晚開始時間", comment: ""))
        ]
        
        // 創建數據集
        let dataSet = BarChartDataSet(entries: entries, label: NSLocalizedString("預測睡眠時間", comment: ""))
        dataSet.colors = [.systemBlue]
        dataSet.valueTextColor = .black
        dataSet.valueFont = .systemFont(ofSize: 12)
        
        // 創建圖表數據
        let data = BarChartData(dataSet: dataSet)
        
        return data
    }
    
    /// 獲取圖表標題
    /// - Returns: 圖表標題
    func getChartTitle() -> String {
        return NSLocalizedString("睡眠預測", comment: "")
    }
    
    /// 獲取圖表描述
    /// - Returns: 圖表描述
    func getChartDescription() -> String? {
        guard let nextSleep = predictionResult.nextSleep else {
            return NSLocalizedString("無法預測下次睡眠時間", comment: "")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let earliestTimeString = formatter.string(from: nextSleep.earliestStartTime)
        let latestTimeString = formatter.string(from: nextSleep.latestStartTime)
        let durationHours = nextSleep.expectedDuration / 3600
        
        return String(format: NSLocalizedString("預計睡眠時間：%@-%@\n預計睡眠時長：%.1f小時\n預測準確度：%.0f%%\n預測來源：%@", comment: ""),
                      earliestTimeString,
                      latestTimeString,
                      durationHours,
                      nextSleep.confidence * 100,
                      predictionResult.isCloudPrediction ? NSLocalizedString("雲端預測", comment: "") : NSLocalizedString("本地預測", comment: ""))
    }
}

// MARK: - 圖表顏色調色板

/// 圖表顏色調色板，提供圖表顏色
class ChartColorPalette {
    // MARK: - 單例
    
    static let shared = ChartColorPalette()
    
    private init() {}
    
    // MARK: - 顏色集合
    
    /// 獲取餅圖顏色
    /// - Parameter count: 顏色數量
    /// - Returns: 顏色數組
    func getPieChartColors(count: Int) -> [UIColor] {
        let baseColors: [UIColor] = [
            .systemBlue,
            .systemGreen,
            .systemOrange,
            .systemPink,
            .systemPurple,
            .systemTeal,
            .systemYellow,
            .systemIndigo
        ]
        
        if count <= baseColors.count {
            return Array(baseColors.prefix(count))
        }
        
        // 如果需要更多顏色，生成額外的顏色
        var colors = baseColors
        for i in baseColors.count..<count {
            let hue = CGFloat(i) / CGFloat(count)
            colors.append(UIColor(hue: hue, saturation: 0.7, brightness: 0.8, alpha: 1.0))
        }
        
        return colors
    }
    
    /// 獲取折線圖顏色
    /// - Parameter count: 顏色數量
    /// - Returns: 顏色數組
    func getLineChartColors(count: Int) -> [UIColor] {
        let baseColors: [UIColor] = [
            .systemBlue,
            .systemRed,
            .systemGreen,
            .systemOrange,
            .systemPurple,
            .systemTeal
        ]
        
        if count <= baseColors.count {
            return Array(baseColors.prefix(count))
        }
        
        // 如果需要更多顏色，生成額外的顏色
        var colors = baseColors
        for i in baseColors.count..<count {
            let hue = CGFloat(i) / CGFloat(count)
            colors.append(UIColor(hue: hue, saturation: 0.7, brightness: 0.8, alpha: 1.0))
        }
        
        return colors
    }
}

// MARK: - 圖表視圖工廠

/// 圖表視圖工廠，創建各種圖表視圖
class ChartViewFactory {
    // MARK: - 創建餅圖
    
    /// 創建餅圖
    /// - Parameter dataProvider: 圖表數據提供者
    /// - Returns: 餅圖視圖
    static func createPieChartView(dataProvider: ChartDataProvider) -> PieChartView {
        let chartView = PieChartView()
        
        // 設置圖表數據
        if let data = dataProvider.getChartData() as? PieChartData {
            chartView.data = data
        }
        
        // 設置圖表外觀
        chartView.holeColor = .clear
        chartView.transparentCircleColor = UIColor.white.withAlphaComponent(0.3)
        chartView.transparentCircleRadiusPercent = 0.6
        chartView.holeRadiusPercent = 0.5
        chartView.drawEntryLabelsEnabled = true
        chartView.entryLabelColor = .black
        chartView.entryLabelFont = .systemFont(ofSize: 12)
        
        // 設置圖表描述
        let description = Description()
        description.text = dataProvider.getChartDescription() ?? ""
        description.textColor = .darkGray
        description.font = .systemFont(ofSize: 12)
        chartView.chartDescription = description
        
        // 設置圖表標題
        let title = dataProvider.getChartTitle()
        chartView.centerText = title
        
        // 設置圖例
        chartView.legend.horizontalAlignment = .center
        chartView.legend.verticalAlignment = .bottom
        chartView.legend.orientation = .horizontal
        chartView.legend.drawInside = false
        chartView.legend.font = .systemFont(ofSize: 12)
        
        // 設置動畫
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .easeOutBack)
        
        return chartView
    }
    
    // MARK: - 創建條形圖
    
    /// 創建條形圖
    /// - Parameter dataProvider: 圖表數據提供者
    /// - Returns: 條形圖視圖
    static func createBarChartView(dataProvider: ChartDataProvider) -> BarChartView {
        let chartView = BarChartView()
        
        // 設置圖表數據
        if let data = dataProvider.getChartData() as? BarChartData {
            chartView.data = data
        }
        
        // 設置圖表外觀
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.maxVisibleCount = 60
        
        // 設置X軸
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.granularity = 1
        
        // 設置左Y軸
        chartView.leftAxis.axisMinimum = 0
        chartView.leftAxis.drawGridLinesEnabled = true
        chartView.leftAxis.granularity = 1
        
        // 設置右Y軸
        chartView.rightAxis.enabled = false
        
        // 設置圖表描述
        let description = Description()
        description.text = dataProvider.getChartDescription() ?? ""
        description.textColor = .darkGray
        description.font = .systemFont(ofSize: 12)
        chartView.chartDescription = description
        
        // 設置圖表標題
        let title = dataProvider.getChartTitle()
        chartView.noDataText = title
        
        // 設置圖例
        chartView.legend.horizontalAlignment = .center
        chartView.legend.verticalAlignment = .bottom
        chartView.legend.orientation = .horizontal
        chartView.legend.drawInside = false
        chartView.legend.font = .systemFont(ofSize: 12)
        
        // 設置動畫
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .easeOutBack)
        
        return chartView
    }
    
    // MARK: - 創建折線圖
    
    /// 創建折線圖
    /// - Parameter dataProvider: 圖表數據提供者
    /// - Returns: 折線圖視圖
    static func createLineChartView(dataProvider: ChartDataProvider) -> LineChartView {
        let chartView = LineChartView()
        
        // 設置圖表數據
        if let data = dataProvider.getChartData() as? LineChartData {
            chartView.data = data
        }
        
        // 設置圖表外觀
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        chartView.drawGridBackgroundEnabled = false
        
        // 設置X軸
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false
        
        // 設置左Y軸
        chartView.leftAxis.drawGridLinesEnabled = true
        
        // 設置右Y軸
        chartView.rightAxis.enabled = false
        
        // 設置圖表描述
        let description = Description()
        description.text = dataProvider.getChartDescription() ?? ""
        description.textColor = .darkGray
        description.font = .systemFont(ofSize: 12)
        chartView.chartDescription = description
        
        // 設置圖表標題
        let title = dataProvider.getChartTitle()
        chartView.noDataText = title
        
        // 設置圖例
        chartView.legend.horizontalAlignment = .center
        chartView.legend.verticalAlignment = .bottom
        chartView.legend.orientation = .horizontal
        chartView.legend.drawInside = false
        chartView.legend.font = .systemFont(ofSize: 12)
        
        // 設置動畫
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .easeOutBack)
        
        return chartView
    }
}

// MARK: - 分析結果視圖控制器

/// 分析結果視圖控制器，顯示分析結果和圖表
class AnalysisResultViewController: UIViewController {
    // MARK: - 屬性
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let sourceLabel = UILabel()
    private let chartContainerView = UIView()
    private let recommendationsLabel = UILabel()
    private let recommendationsTextView = UITextView()
    
    private var chartView: UIView?
    
    // MARK: - 初始化
    
    /// 初始化分析結果視圖控制器
    /// - Parameters:
    ///   - title: 標題
    ///   - source: 數據來源
    ///   - chartDataProvider: 圖表數據提供者
    ///   - chartType: 圖表類型
    ///   - recommendations: 建議
    init(title: String, source: String, chartDataProvider: ChartDataProvider, chartType: ChartType, recommendations: [String]) {
        super.init(nibName: nil, bundle: nil)
        
        self.title = title
        setupUI()
        setupChart(dataProvider: chartDataProvider, chartType: chartType)
        updateContent(title: title, source: source, recommendations: recommendations)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
    }
    
    // MARK: - 私有方法
    
    /// 設置UI
    private func setupUI() {
        // 設置滾動視圖
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // 設置內容視圖
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // 設置標題標籤
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // 設置來源標籤
        sourceLabel.font = .systemFont(ofSize: 14)
        sourceLabel.textColor = .secondaryLabel
        sourceLabel.textAlignment = .center
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sourceLabel)
        
        // 設置圖表容器視圖
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartContainerView)
        
        // 設置建議標籤
        recommendationsLabel.text = NSLocalizedString("建議", comment: "")
        recommendationsLabel.font = .systemFont(ofSize: 20, weight: .bold)
        recommendationsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recommendationsLabel)
        
        // 設置建議文本視圖
        recommendationsTextView.isEditable = false
        recommendationsTextView.isScrollEnabled = false
        recommendationsTextView.font = .systemFont(ofSize: 16)
        recommendationsTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        recommendationsTextView.layer.cornerRadius = 8
        recommendationsTextView.layer.borderWidth = 1
        recommendationsTextView.layer.borderColor = UIColor.systemGray4.cgColor
        recommendationsTextView.backgroundColor = UIColor.systemGray6
        recommendationsTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recommendationsTextView)
        
        // 設置約束
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            sourceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            sourceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sourceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            chartContainerView.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 20),
            chartContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            chartContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            chartContainerView.heightAnchor.constraint(equalToConstant: 300),
            
            recommendationsLabel.topAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: 20),
            recommendationsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recommendationsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            recommendationsTextView.topAnchor.constraint(equalTo: recommendationsLabel.bottomAnchor, constant: 8),
            recommendationsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recommendationsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            recommendationsTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    /// 設置圖表
    /// - Parameters:
    ///   - dataProvider: 圖表數據提供者
    ///   - chartType: 圖表類型
    private func setupChart(dataProvider: ChartDataProvider, chartType: ChartType) {
        // 移除現有的圖表視圖
        chartView?.removeFromSuperview()
        
        // 創建新的圖表視圖
        switch chartType {
        case .pie:
            chartView = ChartViewFactory.createPieChartView(dataProvider: dataProvider)
        case .bar:
            chartView = ChartViewFactory.createBarChartView(dataProvider: dataProvider)
        case .line:
            chartView = ChartViewFactory.createLineChartView(dataProvider: dataProvider)
        }
        
        // 添加圖表視圖到容器
        if let chartView = chartView {
            chartView.translatesAutoresizingMaskIntoConstraints = false
            chartContainerView.addSubview(chartView)
            
            NSLayoutConstraint.activate([
                chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
                chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
                chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
                chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
            ])
        }
    }
    
    /// 更新內容
    /// - Parameters:
    ///   - title: 標題
    ///   - source: 數據來源
    ///   - recommendations: 建議
    private func updateContent(title: String, source: String, recommendations: [String]) {
        titleLabel.text = title
        sourceLabel.text = source
        
        // 格式化建議
        var recommendationsText = ""
        for (index, recommendation) in recommendations.enumerated() {
            recommendationsText += "\(index + 1). \(recommendation)\n\n"
        }
        
        recommendationsTextView.text = recommendationsText
    }
}

// MARK: - 圖表類型枚舉

/// 圖表類型枚舉
enum ChartType {
    /// 餅圖
    case pie
    /// 條形圖
    case bar
    /// 折線圖
    case line
}

// MARK: - 分析結果視圖控制器工廠

/// 分析結果視圖控制器工廠，創建各種分析結果視圖控制器
class AnalysisResultViewControllerFactory {
    // MARK: - 創建睡眠分析結果視圖控制器
    
    /// 創建睡眠分析結果視圖控制器
    /// - Parameter sleepPatternResult: 睡眠模式分析結果
    /// - Returns: 睡眠分析結果視圖控制器
    static func createSleepAnalysisResultViewController(sleepPatternResult: SleepPatternResult) -> AnalysisResultViewController {
        let dataProvider = SleepPatternChartDataProvider(sleepPatternResult: sleepPatternResult)
        let source = sleepPatternResult.isCloudAnalysis ? 
            NSLocalizedString("由Deepseek AI雲端分析提供", comment: "") : 
            NSLocalizedString("由本地分析提供", comment: "")
        
        return AnalysisResultViewController(
            title: NSLocalizedString("睡眠模式分析", comment: ""),
            source: source,
            chartDataProvider: dataProvider,
            chartType: .pie,
            recommendations: sleepPatternResult.recommendations
        )
    }
    
    // MARK: - 創建作息分析結果視圖控制器
    
    /// 創建作息分析結果視圖控制器
    /// - Parameter routineAnalysisResult: 作息分析結果
    /// - Returns: 作息分析結果視圖控制器
    static func createRoutineAnalysisResultViewController(routineAnalysisResult: RoutineAnalysisResult) -> AnalysisResultViewController {
        let dataProvider = RoutineAnalysisChartDataProvider(routineAnalysisResult: routineAnalysisResult)
        let source = routineAnalysisResult.isCloudAnalysis ? 
            NSLocalizedString("由Deepseek AI雲端分析提供", comment: "") : 
            NSLocalizedString("由本地分析提供", comment: "")
        
        return AnalysisResultViewController(
            title: NSLocalizedString("作息分析", comment: ""),
            source: source,
            chartDataProvider: dataProvider,
            chartType: .pie,
            recommendations: routineAnalysisResult.recommendations
        )
    }
    
    // MARK: - 創建預測結果視圖控制器
    
    /// 創建預測結果視圖控制器
    /// - Parameter predictionResult: 預測結果
    /// - Returns: 預測結果視圖控制器
    static func createPredictionResultViewController(predictionResult: PredictionResult) -> AnalysisResultViewController {
        let dataProvider = PredictionChartDataProvider(predictionResult: predictionResult)
        let source = predictionResult.isCloudPrediction ? 
            NSLocalizedString("由Deepseek AI雲端預測提供", comment: "") : 
            NSLocalizedString("由本地預測提供", comment: "")
        
        return AnalysisResultViewController(
            title: NSLocalizedString("睡眠預測", comment: ""),
            source: source,
            chartDataProvider: dataProvider,
            chartType: .bar,
            recommendations: predictionResult.recommendations
        )
    }
}

// analysis_progress_transparency.swift
// 寶寶生活記錄專業版（Baby Tracker）- 整合改進
// 分析過程透明度實現

import Foundation
import UIKit
import Combine

// MARK: - 分析狀態枚舉

/// 分析狀態枚舉，表示當前分析過程的狀態
enum AnalysisStatus {
    /// 未開始
    case notStarted
    /// 數據收集中
    case collectingData(progress: Double)
    /// 本地分析中
    case localAnalyzing(progress: Double)
    /// 雲端分析中
    case cloudAnalyzing(progress: Double)
    /// 結果處理中
    case processingResults(progress: Double)
    /// 完成
    case completed
    /// 失敗
    case failed(error: Error)
    
    /// 是否為進行中狀態
    var isInProgress: Bool {
        switch self {
        case .notStarted, .completed, .failed:
            return false
        default:
            return true
        }
    }
    
    /// 進度值（0-1）
    var progress: Double {
        switch self {
        case .notStarted:
            return 0.0
        case .collectingData(let progress):
            return progress * 0.25
        case .localAnalyzing(let progress), .cloudAnalyzing(let progress):
            return 0.25 + progress * 0.5
        case .processingResults(let progress):
            return 0.75 + progress * 0.25
        case .completed:
            return 1.0
        case .failed:
            return 0.0
        }
    }
    
    /// 狀態描述
    var description: String {
        switch self {
        case .notStarted:
            return NSLocalizedString("準備分析...", comment: "")
        case .collectingData:
            return NSLocalizedString("收集數據中...", comment: "")
        case .localAnalyzing:
            return NSLocalizedString("本地分析中...", comment: "")
        case .cloudAnalyzing:
            return NSLocalizedString("雲端分析中...", comment: "")
        case .processingResults:
            return NSLocalizedString("處理結果中...", comment: "")
        case .completed:
            return NSLocalizedString("分析完成", comment: "")
        case .failed(let error):
            return String(format: NSLocalizedString("分析失敗：%@", comment: ""), error.localizedDescription)
        }
    }
    
    /// 詳細描述
    var detailedDescription: String {
        switch self {
        case .notStarted:
            return NSLocalizedString("分析尚未開始。", comment: "")
        case .collectingData(let progress):
            return String(format: NSLocalizedString("正在收集分析所需的數據...（%.0f%%）", comment: ""), progress * 100)
        case .localAnalyzing(let progress):
            return String(format: NSLocalizedString("正在使用本地AI引擎進行分析...（%.0f%%）", comment: ""), progress * 100)
        case .cloudAnalyzing(let progress):
            return String(format: NSLocalizedString("正在使用Deepseek雲端AI進行分析...（%.0f%%）", comment: ""), progress * 100)
        case .processingResults(let progress):
            return String(format: NSLocalizedString("正在處理分析結果...（%.0f%%）", comment: ""), progress * 100)
        case .completed:
            return NSLocalizedString("分析已完成，結果已準備就緒。", comment: "")
        case .failed(let error):
            return String(format: NSLocalizedString("分析失敗：%@。請稍後重試或聯繫客服獲取支持。", comment: ""), error.localizedDescription)
        }
    }
}

// MARK: - 分析類型枚舉

/// 分析類型枚舉，表示當前進行的分析類型
enum AnalysisType {
    /// 睡眠分析
    case sleep
    /// 作息分析
    case routine
    /// 預測分析
    case prediction
    
    /// 分析類型名稱
    var name: String {
        switch self {
        case .sleep:
            return NSLocalizedString("睡眠分析", comment: "")
        case .routine:
            return NSLocalizedString("作息分析", comment: "")
        case .prediction:
            return NSLocalizedString("預測分析", comment: "")
        }
    }
}

// MARK: - 分析上下文

/// 分析上下文，包含分析相關的上下文信息
struct AnalysisContext {
    /// 分析類型
    let type: AnalysisType
    
    /// 寶寶ID
    let babyId: String
    
    /// 寶寶名稱
    let babyName: String
    
    /// 分析時間範圍
    let dateRange: ClosedRange<Date>
    
    /// 是否使用雲端分析
    let useCloudAnalysis: Bool
    
    /// 分析敏感度
    let sensitivity: AnalysisSensitivity
    
    /// 數據記錄數量
    var recordCount: Int = 0
    
    /// 格式化的時間範圍字符串
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let startString = formatter.string(from: dateRange.lowerBound)
        let endString = formatter.string(from: dateRange.upperBound)
        
        return "\(startString) - \(endString)"
    }
    
    /// 上下文描述
    var description: String {
        let analysisSource = useCloudAnalysis ? 
            NSLocalizedString("雲端分析", comment: "") : 
            NSLocalizedString("本地分析", comment: "")
        
        return String(format: NSLocalizedString("為%@進行%@\n時間範圍：%@\n分析方式：%@\n敏感度：%@\n數據記錄：%d條", comment: ""),
                      babyName,
                      type.name,
                      formattedDateRange,
                      analysisSource,
                      sensitivity.localizedName,
                      recordCount)
    }
}

// MARK: - 分析進度追蹤器

/// 分析進度追蹤器，負責追蹤和報告分析進度
class AnalysisProgressTracker {
    // MARK: - 屬性
    
    /// 當前分析狀態
    private let statusSubject = CurrentValueSubject<AnalysisStatus, Never>(.notStarted)
    
    /// 分析上下文
    private let contextSubject = CurrentValueSubject<AnalysisContext?, Never>(nil)
    
    /// 分析開始時間
    private var startTime: Date?
    
    /// 分析耗時（秒）
    private let elapsedTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    
    /// 定時器
    private var timer: Timer?
    
    /// 取消訂閱集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 公開的發布者
    
    /// 分析狀態發布者
    var statusPublisher: AnyPublisher<AnalysisStatus, Never> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    /// 分析上下文發布者
    var contextPublisher: AnyPublisher<AnalysisContext?, Never> {
        return contextSubject.eraseToAnyPublisher()
    }
    
    /// 分析耗時發布者
    var elapsedTimePublisher: AnyPublisher<TimeInterval, Never> {
        return elapsedTimeSubject.eraseToAnyPublisher()
    }
    
    // MARK: - 初始化
    
    init() {}
    
    // MARK: - 公開方法
    
    /// 開始分析
    /// - Parameter context: 分析上下文
    func startAnalysis(context: AnalysisContext) {
        // 重置狀態
        statusSubject.send(.notStarted)
        contextSubject.send(context)
        startTime = Date()
        elapsedTimeSubject.send(0)
        
        // 啟動定時器
        startTimer()
        
        // 更新狀態為數據收集中
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateStatus(.collectingData(progress: 0.0))
        }
    }
    
    /// 更新分析狀態
    /// - Parameter status: 新狀態
    func updateStatus(_ status: AnalysisStatus) {
        statusSubject.send(status)
        
        // 如果分析完成或失敗，停止定時器
        if case .completed = status, case .failed = status {
            stopTimer()
        }
    }
    
    /// 更新分析上下文
    /// - Parameter context: 新上下文
    func updateContext(_ context: AnalysisContext) {
        contextSubject.send(context)
    }
    
    /// 更新數據記錄數量
    /// - Parameter count: 記錄數量
    func updateRecordCount(_ count: Int) {
        guard var context = contextSubject.value else { return }
        context.recordCount = count
        contextSubject.send(context)
    }
    
    /// 完成分析
    func completeAnalysis() {
        statusSubject.send(.completed)
        stopTimer()
    }
    
    /// 失敗分析
    /// - Parameter error: 錯誤
    func failAnalysis(error: Error) {
        statusSubject.send(.failed(error: error))
        stopTimer()
    }
    
    // MARK: - 私有方法
    
    /// 啟動定時器
    private func startTimer() {
        // 停止現有定時器
        stopTimer()
        
        // 啟動新定時器
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            self.elapsedTimeSubject.send(elapsed)
        }
    }
    
    /// 停止定時器
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - 分析進度視圖

/// 分析進度視圖，顯示分析進度和上下文信息
class AnalysisProgressView: UIView {
    // MARK: - UI元素
    
    private let titleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let statusLabel = UILabel()
    private let contextTextView = UITextView()
    private let elapsedTimeLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - 回調
    
    /// 取消按鈕點擊回調
    var onCancelTapped: (() -> Void)?
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - 私有方法
    
    /// 設置UI
    private func setupUI() {
        // 設置背景色和圓角
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        
        // 設置標題標籤
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // 設置進度視圖
        progressView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressView)
        
        // 設置狀態標籤
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        
        // 設置上下文文本視圖
        contextTextView.font = .systemFont(ofSize: 14)
        contextTextView.isEditable = false
        contextTextView.isScrollEnabled = true
        contextTextView.backgroundColor = .systemGray6
        contextTextView.layer.cornerRadius = 8
        contextTextView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contextTextView)
        
        // 設置耗時標籤
        elapsedTimeLabel.font = .systemFont(ofSize: 14)
        elapsedTimeLabel.textAlignment = .center
        elapsedTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(elapsedTimeLabel)
        
        // 設置取消按鈕
        cancelButton.setTitle(NSLocalizedString("取消", comment: ""), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cancelButton)
        
        // 設置約束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            contextTextView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            contextTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contextTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contextTextView.heightAnchor.constraint(equalToConstant: 120),
            
            elapsedTimeLabel.topAnchor.constraint(equalTo: contextTextView.bottomAnchor, constant: 16),
            elapsedTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            elapsedTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            cancelButton.topAnchor.constraint(equalTo: elapsedTimeLabel.bottomAnchor, constant: 16),
            cancelButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    /// 取消按鈕點擊
    @objc private func cancelButtonTapped() {
        onCancelTapped?()
    }
    
    // MARK: - 公開方法
    
    /// 更新分析類型
    /// - Parameter type: 分析類型
    func updateAnalysisType(_ type: AnalysisType) {
        titleLabel.text = type.name
    }
    
    /// 更新分析狀態
    /// - Parameter status: 分析狀態
    func updateStatus(_ status: AnalysisStatus) {
        // 更新進度條
        progressView.progress = Float(status.progress)
        
        // 更新狀態標籤
        statusLabel.text = status.description
        
        // 更新取消按鈕狀態
        cancelButton.isEnabled = status.isInProgress
    }
    
    /// 更新分析上下文
    /// - Parameter context: 分析上下文
    func updateContext(_ context: AnalysisContext?) {
        guard let context = context else {
            contextTextView.text = ""
            return
        }
        
        // 更新標題
        titleLabel.text = context.type.name
        
        // 更新上下文文本
        contextTextView.text = context.description
    }
    
    /// 更新分析耗時
    /// - Parameter elapsedTime: 耗時（秒）
    func updateElapsedTime(_ elapsedTime: TimeInterval) {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        elapsedTimeLabel.text = String(format: NSLocalizedString("耗時：%02d:%02d", comment: ""), minutes, seconds)
    }
}

// MARK: - 分析進度控制器

/// 分析進度控制器，管理分析進度視圖和追蹤器
class AnalysisProgressController {
    // MARK: - 屬性
    
    private let progressTracker = AnalysisProgressTracker()
    private let progressView = AnalysisProgressView()
    private var cancellables = Set<AnyCancellable>()
    
    /// 取消回調
    var onCancel: (() -> Void)?
    
    // MARK: - 初始化
    
    init() {
        setupBindings()
    }
    
    // MARK: - 私有方法
    
    /// 設置綁定
    private func setupBindings() {
        // 綁定分析狀態
        progressTracker.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.progressView.updateStatus(status)
            }
            .store(in: &cancellables)
        
        // 綁定分析上下文
        progressTracker.contextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.progressView.updateContext(context)
            }
            .store(in: &cancellables)
        
        // 綁定分析耗時
        progressTracker.elapsedTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] elapsedTime in
                self?.progressView.updateElapsedTime(elapsedTime)
            }
            .store(in: &cancellables)
        
        // 設置取消按鈕回調
        progressView.onCancelTapped = { [weak self] in
            self?.onCancel?()
        }
    }
    
    // MARK: - 公開方法
    
    /// 獲取進度視圖
    /// - Returns: 進度視圖
    func getProgressView() -> UIView {
        return progressView
    }
    
    /// 獲取進度追蹤器
    /// - Returns: 進度追蹤器
    func getProgressTracker() -> AnalysisProgressTracker {
        return progressTracker
    }
}

// MARK: - AIEngine擴展

extension AIEngine {
    /// 分析睡眠模式（帶進度追蹤）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - babyName: 寶寶名稱
    ///   - dateRange: 日期範圍
    ///   - progressTracker: 進度追蹤器
    /// - Returns: 分析結果發布者
    func analyzeSleepPatternWithProgress(
        babyId: String,
        babyName: String,
        dateRange: ClosedRange<Date>,
        progressTracker: AnalysisProgressTracker
    ) -> AnyPublisher<SleepPatternResult, Error> {
        // 創建分析上下文
        let context = AnalysisContext(
            type: .sleep,
            babyId: babyId,
            babyName: babyName,
            dateRange: dateRange,
            useCloudAnalysis: networkMonitor.canUseCloudAnalysis(),
            sensitivity: AnalysisSettingsManager.shared.settings.sleepAnalysisSensitivity
        )
        
        // 開始分析
        progressTracker.startAnalysis(context: context)
        
        // 檢查是否可以使用雲端分析
        if networkMonitor.canUseCloudAnalysis() {
            // 嘗試使用雲端分析
            return cloudAIService.analyzeSleepPatternCloudWithProgress(
                babyId: babyId,
                dateRange: dateRange,
                progressTracker: progressTracker
            )
            .catch { [weak self] error -> AnyPublisher<SleepPatternResult, Error> in
                guard let self = self else {
                    progressTracker.failAnalysis(error: AIError.engineNotAvailable)
                    return Fail(error: AIError.engineNotAvailable).eraseToAnyPublisher()
                }
                
                // 如果雲端分析失敗（非禁用原因），記錄錯誤
                if !(error is CloudError) {
                    print("雲端睡眠分析失敗：\(error.localizedDescription)，降級到本地分析")
                }
                
                // 降級到本地分析
                return self.analyzeSleepPatternLocalWithProgress(
                    babyId: babyId,
                    babyName: babyName,
                    dateRange: dateRange,
                    progressTracker: progressTracker
                )
            }
            .eraseToAnyPublisher()
        }
        
        // 直接使用本地分析
        return analyzeSleepPatternLocalWithProgress(
            babyId: babyId,
            babyName: babyName,
            dateRange: dateRange,
            progressTracker: progressTracker
        )
    }
    
    /// 本地分析睡眠模式（帶進度追蹤）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - babyName: 寶寶名稱
    ///   - dateRange: 日期範圍
    ///   - progressTracker: 進度追蹤器
    /// - Returns: 分析結果發布者
    private func analyzeSleepPatternLocalWithProgress(
        babyId: String,
        babyName: String,
        dateRange: ClosedRange<Date>,
        progressTracker: AnalysisProgressTracker
    ) -> AnyPublisher<SleepPatternResult, Error> {
        // 更新上下文
        let context = AnalysisContext(
            type: .sleep,
            babyId: babyId,
            babyName: babyName,
            dateRange: dateRange,
            useCloudAnalysis: false,
            sensitivity: AnalysisSettingsManager.shared.settings.sleepAnalysisSensitivity
        )
        progressTracker.updateContext(context)
        
        return Future<SleepPatternResult, Error> { [weak self] promise in
            guard let self = self else {
                progressTracker.failAnalysis(error: AIError.engineNotAvailable)
                promise(.failure(AIError.engineNotAvailable))
                return
            }
            
            Task {
                // 更新狀態為數據收集中
                progressTracker.updateStatus(.collectingData(progress: 0.0))
                
                // 獲取睡眠記錄
                let sleepRecordsResult = await self.sleepUseCase.getSleepRecords(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                // 更新狀態為數據收集完成
                progressTracker.updateStatus(.collectingData(progress: 1.0))
                
                switch sleepRecordsResult {
                case .success(let sleepRecords):
                    // 更新記錄數量
                    progressTracker.updateRecordCount(sleepRecords.count)
                    
                    // 更新狀態為本地分析中
                    progressTracker.updateStatus(.localAnalyzing(progress: 0.0))
                    
                    // 模擬分析過程
                    for i in 1...10 {
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                        progressTracker.updateStatus(.localAnalyzing(progress: Double(i) / 10.0))
                    }
                    
                    // 使用本地分析器分析
                    let result = self.sleepPatternAnalyzer.analyze(sleepRecords: sleepRecords)
                    
                    // 更新狀態為處理結果中
                    progressTracker.updateStatus(.processingResults(progress: 0.0))
                    
                    // 模擬結果處理
                    for i in 1...5 {
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                        progressTracker.updateStatus(.processingResults(progress: Double(i) / 5.0))
                    }
                    
                    // 完成分析
                    progressTracker.completeAnalysis()
                    promise(.success(result))
                    
                case .failure(let error):
                    // 失敗分析
                    progressTracker.failAnalysis(error: error)
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - CloudAIService擴展

extension CloudAIService {
    /// 分析睡眠模式（雲端，帶進度追蹤）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    ///   - progressTracker: 進度追蹤器
    /// - Returns: 分析結果發布者
    func analyzeSleepPatternCloudWithProgress(
        babyId: String,
        dateRange: ClosedRange<Date>,
        progressTracker: AnalysisProgressTracker
    ) -> AnyPublisher<SleepPatternResult, Error> {
        // 檢查是否可以使用雲端分析
        guard networkMonitor.canUseCloudAnalysis() else {
            progressTracker.failAnalysis(error: CloudError.cloudAnalysisDisabled)
            return Fail(error: CloudError.cloudAnalysisDisabled).eraseToAnyPublisher()
        }
        
        return Future<SleepPatternResult, Error> { [weak self] promise in
            guard let self = self else {
                progressTracker.failAnalysis(error: CloudError.unknownError)
                promise(.failure(CloudError.unknownError))
                return
            }
            
            Task {
                // 更新狀態為數據收集中
                progressTracker.updateStatus(.collectingData(progress: 0.0))
                
                // 獲取睡眠記錄
                let sleepRecordsResult = await self.sleepUseCase.getSleepRecords(
                    babyId: babyId,
                    dateRange: dateRange
                )
                
                // 更新狀態為數據收集完成
                progressTracker.updateStatus(.collectingData(progress: 1.0))
                
                switch sleepRecordsResult {
                case .success(let sleepRecords):
                    // 更新記錄數量
                    progressTracker.updateRecordCount(sleepRecords.count)
                    
                    // 檢查記錄數量
                    guard !sleepRecords.isEmpty else {
                        progressTracker.failAnalysis(error: CloudError.insufficientData)
                        promise(.failure(CloudError.insufficientData))
                        return
                    }
                    
                    // 檢查緩存
                    let cacheKey = self.generateCacheKey(babyId: babyId, dateRange: dateRange, type: "sleep")
                    if let cachedResult = self.sleepAnalysisCache[cacheKey],
                       self.isCacheValid(cacheKey: cacheKey) {
                        // 更新狀態為處理結果中
                        progressTracker.updateStatus(.processingResults(progress: 0.0))
                        
                        // 使用轉換器轉換緩存結果
                        let converter = DataConverterFactory.getSleepAnalysisConverter()
                        let result = converter.convert(cachedResult)
                        
                        // 模擬結果處理
                        for i in 1...5 {
                            try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                            progressTracker.updateStatus(.processingResults(progress: Double(i) / 5.0))
                        }
                        
                        // 完成分析
                        progressTracker.completeAnalysis()
                        promise(.success(result))
                        return
                    }
                    
                    // 匿名化數據
                    progressTracker.updateStatus(.cloudAnalyzing(progress: 0.1))
                    let anonymizedData = self.dataAnonymizer.anonymizeSleepRecords(sleepRecords)
                    progressTracker.updateStatus(.cloudAnalyzing(progress: 0.2))
                    
                    // 調用API
                    progressTracker.updateStatus(.cloudAnalyzing(progress: 0.3))
                    let apiResult = await self.apiClient.analyzeSleep(data: anonymizedData)
                    progressTracker.updateStatus(.cloudAnalyzing(progress: 0.8))
                    
                    switch apiResult {
                    case .success(let response):
                        // 更新緩存
                        self.sleepAnalysisCache[cacheKey] = response
                        progressTracker.updateStatus(.cloudAnalyzing(progress: 0.9))
                        
                        // 更新狀態為處理結果中
                        progressTracker.updateStatus(.processingResults(progress: 0.0))
                        
                        // 使用轉換器轉換API結果
                        let converter = DataConverterFactory.getSleepAnalysisConverter()
                        let result = converter.convert(response)
                        
                        // 模擬結果處理
                        for i in 1...5 {
                            try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                            progressTracker.updateStatus(.processingResults(progress: Double(i) / 5.0))
                        }
                        
                        // 完成分析
                        progressTracker.completeAnalysis()
                        promise(.success(result))
                        
                    case .failure(let apiError):
                        // 失敗分析
                        let error = self.convertAPIError(apiError)
                        progressTracker.failAnalysis(error: error)
                        promise(.failure(error))
                    }
                    
                case .failure(let error):
                    // 失敗分析
                    progressTracker.failAnalysis(error: error)
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - 分析視圖控制器

/// 分析視圖控制器，顯示分析進度和結果
class AnalysisViewController: UIViewController {
    // MARK: - 屬性
    
    private let aiEngine: AIEngine
    private let babyId: String
    private let babyName: String
    private let analysisType: AnalysisType
    private let dateRange: ClosedRange<Date>
    
    private let progressController = AnalysisProgressController()
    private var cancellables = Set<AnyCancellable>()
    
    private var analysisResult: Any?
    
    // MARK: - 初始化
    
    /// 初始化分析視圖控制器
    /// - Parameters:
    ///   - aiEngine: AI引擎
    ///   - babyId: 寶寶ID
    ///   - babyName: 寶寶名稱
    ///   - analysisType: 分析類型
    ///   - dateRange: 日期範圍
    init(
        aiEngine: AIEngine,
        babyId: String,
        babyName: String,
        analysisType: AnalysisType,
        dateRange: ClosedRange<Date>
    ) {
        self.aiEngine = aiEngine
        self.babyId = babyId
        self.babyName = babyName
        self.analysisType = analysisType
        self.dateRange = dateRange
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupProgressView()
        setupCancelAction()
        startAnalysis()
    }
    
    // MARK: - 私有方法
    
    /// 設置UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = analysisType.name
        
        // 添加取消按鈕
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
    }
    
    /// 設置進度視圖
    private func setupProgressView() {
        let progressView = progressController.getProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    /// 設置取消動作
    private func setupCancelAction() {
        progressController.onCancel = { [weak self] in
            self?.cancelAnalysis()
        }
    }
    
    /// 開始分析
    private func startAnalysis() {
        let progressTracker = progressController.getProgressTracker()
        
        switch analysisType {
        case .sleep:
            aiEngine.analyzeSleepPatternWithProgress(
                babyId: babyId,
                babyName: babyName,
                dateRange: dateRange,
                progressTracker: progressTracker
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleAnalysisError(error)
                    }
                },
                receiveValue: { [weak self] result in
                    self?.handleSleepAnalysisResult(result)
                }
            )
            .store(in: &cancellables)
            
        case .routine:
            // 實現作息分析
            break
            
        case .prediction:
            // 實現預測分析
            break
        }
    }
    
    /// 取消分析
    private func cancelAnalysis() {
        // 取消所有訂閱
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // 關閉視圖控制器
        dismiss(animated: true)
    }
    
    /// 處理分析錯誤
    /// - Parameter error: 錯誤
    private func handleAnalysisError(_ error: Error) {
        let alert = UIAlertController(
            title: NSLocalizedString("分析失敗", comment: ""),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("確定", comment: ""),
            style: .default,
            handler: { [weak self] _ in
                self?.dismiss(animated: true)
            }
        ))
        
        present(alert, animated: true)
    }
    
    /// 處理睡眠分析結果
    /// - Parameter result: 睡眠分析結果
    private func handleSleepAnalysisResult(_ result: SleepPatternResult) {
        self.analysisResult = result
        
        // 顯示結果視圖控制器
        let resultVC = AnalysisResultViewControllerFactory.createSleepAnalysisResultViewController(sleepPatternResult: result)
        
        // 延遲一秒，讓用戶看到完成狀態
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.navigationController?.pushViewController(resultVC, animated: true)
        }
    }
    
    /// 取消按鈕點擊
    @objc private func cancelButtonTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("取消分析", comment: ""),
            message: NSLocalizedString("確定要取消當前分析嗎？", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("繼續分析", comment: ""),
            style: .cancel
        ))
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("取消分析", comment: ""),
            style: .destructive,
            handler: { [weak self] _ in
                self?.cancelAnalysis()
            }
        ))
        
        present(alert, animated: true)
    }
}

// MARK: - 工廠方法

/// 創建分析視圖控制器
/// - Parameters:
///   - aiEngine: AI引擎
///   - babyId: 寶寶ID
///   - babyName: 寶寶名稱
///   - analysisType: 分析類型
///   - dateRange: 日期範圍
/// - Returns: 分析視圖控制器
func createAnalysisViewController(
    aiEngine: AIEngine,
    babyId: String,
    babyName: String,
    analysisType: AnalysisType,
    dateRange: ClosedRange<Date>
) -> UINavigationController {
    let viewController = AnalysisViewController(
        aiEngine: aiEngine,
        babyId: babyId,
        babyName: babyName,
        analysisType: analysisType,
        dateRange: dateRange
    )
    
    let navigationController = UINavigationController(rootViewController: viewController)
    return navigationController
}

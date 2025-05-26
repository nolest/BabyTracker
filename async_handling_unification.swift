// async_handling_unification.swift
// 寶寶生活記錄專業版（Baby Tracker）- 整合改進
// 異步處理模式統一實現

import Foundation
import Combine

// MARK: - Combine與Async/Await橋接擴展

/// Publisher的異步擴展，提供Combine與Async/Await之間的橋接
extension Publisher {
    /// 將Publisher轉換為異步操作
    /// - Returns: Publisher的輸出值
    /// - Throws: Publisher的錯誤
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                    cancellable?.cancel()
                }
            )
        }
    }
}

// MARK: - 異步操作的Combine擴展

/// 為異步操作提供Combine包裝
extension AIEngine {
    // MARK: - 原始異步方法的Combine包裝
    
    /// 分析睡眠模式（Combine版本）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果發布者
    func analyzeSleepPattern(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<SleepPatternResult, Error> {
        return Future<SleepPatternResult, Error> { promise in
            Task {
                let result = await self.analyzeSleepPatternAsync(babyId: babyId, dateRange: dateRange)
                switch result {
                case .success(let data):
                    promise(.success(data))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 分析作息模式（Combine版本）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 分析結果發布者
    func analyzeRoutine(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<RoutineAnalysisResult, Error> {
        return Future<RoutineAnalysisResult, Error> { promise in
            Task {
                let result = await self.analyzeRoutineAsync(babyId: babyId, dateRange: dateRange)
                switch result {
                case .success(let data):
                    promise(.success(data))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 預測下次睡眠（Combine版本）
    /// - Parameter babyId: 寶寶ID
    /// - Returns: 預測結果發布者
    func predictNextSleep(babyId: String) -> AnyPublisher<PredictionResult, Error> {
        return Future<PredictionResult, Error> { promise in
            Task {
                let result = await self.predictNextSleepAsync(babyId: babyId)
                switch result {
                case .success(let data):
                    promise(.success(data))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - 存儲庫異步擴展

/// 為存儲庫提供Combine包裝
extension SleepRepository {
    /// 獲取睡眠記錄（Combine版本）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 睡眠記錄發布者
    func getSleepRecordsPublisher(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<[SleepRecord], Error> {
        return Future<[SleepRecord], Error> { promise in
            Task {
                let result = await self.getSleepRecords(babyId: babyId, dateRange: dateRange)
                switch result {
                case .success(let records):
                    promise(.success(records))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension FeedingRepository {
    /// 獲取餵食記錄（Combine版本）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 餵食記錄發布者
    func getFeedingRecordsPublisher(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<[FeedingRecord], Error> {
        return Future<[FeedingRecord], Error> { promise in
            Task {
                let result = await self.getFeedingRecords(babyId: babyId, dateRange: dateRange)
                switch result {
                case .success(let records):
                    promise(.success(records))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension ActivityRepository {
    /// 獲取活動記錄（Combine版本）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 活動記錄發布者
    func getActivitiesPublisher(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<[Activity], Error> {
        return Future<[Activity], Error> { promise in
            Task {
                let result = await self.getActivities(babyId: babyId, dateRange: dateRange)
                switch result {
                case .success(let activities):
                    promise(.success(activities))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - 用例異步擴展

/// 為用例提供Combine包裝
extension SleepUseCase {
    /// 獲取睡眠記錄（Combine版本）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 睡眠記錄發布者
    func getSleepRecordsPublisher(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<[SleepRecord], Error> {
        return Future<[SleepRecord], Error> { promise in
            Task {
                let result = await self.getSleepRecords(babyId: babyId, dateRange: dateRange)
                switch result {
                case .success(let records):
                    promise(.success(records))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension FeedingUseCase {
    /// 獲取餵食記錄（Combine版本）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 餵食記錄發布者
    func getFeedingRecordsPublisher(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<[FeedingRecord], Error> {
        return Future<[FeedingRecord], Error> { promise in
            Task {
                let result = await self.getFeedingRecords(babyId: babyId, dateRange: dateRange)
                switch result {
                case .success(let records):
                    promise(.success(records))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension ActivityUseCase {
    /// 獲取活動記錄（Combine版本）
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    /// - Returns: 活動記錄發布者
    func getActivitiesPublisher(
        babyId: String,
        dateRange: ClosedRange<Date>
    ) -> AnyPublisher<[Activity], Error> {
        return Future<[Activity], Error> { promise in
            Task {
                let result = await self.getActivities(babyId: babyId, dateRange: dateRange)
                switch result {
                case .success(let activities):
                    promise(.success(activities))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - ViewModel異步處理示例

/// 睡眠分析視圖模型，展示統一異步處理模式的使用
class SleepAnalysisViewModel {
    // MARK: - 依賴
    
    private let aiEngine: AIEngine
    private let errorHandler: ErrorHandler
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 發布者
    
    private let analysisResultSubject = CurrentValueSubject<SleepPatternResult?, Never>(nil)
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorMessageSubject = CurrentValueSubject<String?, Never>(nil)
    
    // MARK: - 公開的發布者
    
    /// 分析結果發布者
    var analysisResult: AnyPublisher<SleepPatternResult?, Never> {
        return analysisResultSubject.eraseToAnyPublisher()
    }
    
    /// 加載狀態發布者
    var isLoading: AnyPublisher<Bool, Never> {
        return isLoadingSubject.eraseToAnyPublisher()
    }
    
    /// 錯誤信息發布者
    var errorMessage: AnyPublisher<String?, Never> {
        return errorMessageSubject.eraseToAnyPublisher()
    }
    
    // MARK: - 初始化
    
    /// 初始化睡眠分析視圖模型
    /// - Parameters:
    ///   - aiEngine: AI引擎
    ///   - errorHandler: 錯誤處理器
    init(aiEngine: AIEngine, errorHandler: ErrorHandler) {
        self.aiEngine = aiEngine
        self.errorHandler = errorHandler
    }
    
    // MARK: - 公開方法
    
    /// 分析睡眠模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    func analyzeSleepPattern(babyId: String, dateRange: ClosedRange<Date>) {
        isLoadingSubject.send(true)
        errorMessageSubject.send(nil)
        
        aiEngine.analyzeSleepPattern(babyId: babyId, dateRange: dateRange)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoadingSubject.send(false)
                    
                    if case .failure(let error) = completion {
                        self.errorHandler.handle(error)
                        self.errorMessageSubject.send(self.errorHandler.getErrorMessage(for: error))
                    }
                },
                receiveValue: { [weak self] result in
                    self?.analysisResultSubject.send(result)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 使用異步方法分析睡眠模式
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - dateRange: 日期範圍
    func analyzeSleepPatternAsync(babyId: String, dateRange: ClosedRange<Date>) async {
        DispatchQueue.main.async {
            self.isLoadingSubject.send(true)
            self.errorMessageSubject.send(nil)
        }
        
        do {
            let result = try await aiEngine.analyzeSleepPattern(babyId: babyId, dateRange: dateRange)
                .async()
            
            DispatchQueue.main.async {
                self.analysisResultSubject.send(result)
                self.isLoadingSubject.send(false)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorHandler.handle(error)
                self.errorMessageSubject.send(self.errorHandler.getErrorMessage(for: error))
                self.isLoadingSubject.send(false)
            }
        }
    }
}

// MARK: - 視圖控制器異步處理示例

/// 睡眠分析視圖控制器，展示統一異步處理模式的使用
class SleepAnalysisViewController: UIViewController {
    // MARK: - 屬性
    
    private let viewModel: SleepAnalysisViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI元素
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    
    // MARK: - 初始化
    
    /// 初始化睡眠分析視圖控制器
    /// - Parameter viewModel: 睡眠分析視圖模型
    init(viewModel: SleepAnalysisViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命週期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindViewModel()
    }
    
    // MARK: - 私有方法
    
    /// 設置UI
    private func setupUI() {
        // 設置加載指示器
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        // 設置錯誤標籤
        errorLabel.textColor = .red
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        
        // 設置約束
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    /// 綁定視圖模型
    private func bindViewModel() {
        // 綁定加載狀態
        viewModel.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        // 綁定錯誤信息
        viewModel.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage, !errorMessage.isEmpty {
                    self?.errorLabel.text = errorMessage
                    self?.errorLabel.isHidden = false
                } else {
                    self?.errorLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
        
        // 綁定分析結果
        viewModel.analysisResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                if let result = result {
                    self?.updateUI(with: result)
                }
            }
            .store(in: &cancellables)
    }
    
    /// 更新UI
    /// - Parameter result: 睡眠模式分析結果
    private func updateUI(with result: SleepPatternResult) {
        // 更新UI以顯示分析結果
    }
    
    // MARK: - 動作
    
    /// 分析按鈕點擊
    @objc private func analyzeButtonTapped() {
        // 使用Combine方式
        let babyId = "current_baby_id" // 從某處獲取
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate
        viewModel.analyzeSleepPattern(babyId: babyId, dateRange: startDate...endDate)
    }
    
    /// 異步分析按鈕點擊
    @objc private func asyncAnalyzeButtonTapped() {
        // 使用異步方式
        let babyId = "current_baby_id" // 從某處獲取
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate
        
        Task {
            await viewModel.analyzeSleepPatternAsync(babyId: babyId, dateRange: startDate...endDate)
        }
    }
}

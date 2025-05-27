import Foundation
import Combine

class PredictionViewModel {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: Error? = nil
    @Published var currentPrediction: PredictionDisplay? = nil
    
    // MARK: - Dependencies
    private let aiEngine: AIEngine
    private let predictionEngine: PredictionEngine
    private let userSettings: UserSettings
    private let networkMonitor: NetworkMonitor
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var predictionType: PredictionType = .sleep
    private var timeframe: Date = Date().addingTimeInterval(3600) // Default 1 hour in future
    
    // MARK: - Initialization
    init(aiEngine: AIEngine, predictionEngine: PredictionEngine, userSettings: UserSettings, networkMonitor: NetworkMonitor) {
        self.aiEngine = aiEngine
        self.predictionEngine = predictionEngine
        self.userSettings = userSettings
        self.networkMonitor = networkMonitor
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadPredictions() {
        guard userSettings.isAIAnalysisEnabled else {
            self.error = AnalysisError.aiAnalysisDisabled
            return
        }
        
        // Check network status if cloud analysis is enabled
        if userSettings.useCloudAnalysis && !networkMonitor.isConnected {
            self.error = NetworkError.noInternetConnection
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let result = try await generatePrediction()
                DispatchQueue.main.async {
                    self.currentPrediction = result
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func updatePredictionType(index: Int) {
        guard let type = PredictionType(rawValue: index) else { return }
        self.predictionType = type
        loadPredictions()
    }
    
    func updateTimeframe(date: Date) {
        self.timeframe = date
        loadPredictions()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Monitor network status changes
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if !isConnected && self?.userSettings.useCloudAnalysis == true {
                    self?.error = NetworkError.noInternetConnection
                } else {
                    self?.error = nil
                }
            }
            .store(in: &cancellables)
        
        // Monitor user settings changes
        userSettings.$isAIAnalysisEnabled
            .sink { [weak self] isEnabled in
                if !isEnabled {
                    self?.error = AnalysisError.aiAnalysisDisabled
                } else {
                    self?.error = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func generatePrediction() async throws -> PredictionDisplay {
        let result: PredictionResult
        
        if userSettings.useCloudAnalysis && networkMonitor.isConnected {
            // Use cloud AI service for prediction
            result = try await aiEngine.generatePrediction(type: predictionType, targetTime: timeframe)
        } else {
            // Use local prediction engine
            result = try await predictionEngine.predictBehavior(type: predictionType, targetTime: timeframe)
        }
        
        // Convert to display model
        return createDisplayModel(from: result)
    }
    
    private func createDisplayModel(from result: PredictionResult) -> PredictionDisplay {
        let title: String
        let description: String
        
        switch predictionType {
        case .sleep:
            title = "睡眠預測"
            description = result.description
        case .feeding:
            title = "餵食預測"
            description = result.description
        case .activity:
            title = "活動預測"
            description = result.description
        }
        
        return PredictionDisplay(
            title: title,
            description: description,
            confidence: result.confidence
        )
    }
    
    // MARK: - Types
    enum PredictionType: Int {
        case sleep = 0
        case feeding = 1
        case activity = 2
    }
    
    struct PredictionDisplay {
        let title: String
        let description: String
        let confidence: Float
    }
}

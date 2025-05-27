import Foundation
import Combine

class AnalysisDashboardViewModel {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: Error? = nil
    
    // MARK: - Dependencies
    private let aiEngine: AIEngine
    private let userSettings: UserSettings
    private let networkMonitor: NetworkMonitor
    private weak var coordinator: AnalysisCoordinator?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(aiEngine: AIEngine, userSettings: UserSettings, networkMonitor: NetworkMonitor, coordinator: AnalysisCoordinator? = nil) {
        self.aiEngine = aiEngine
        self.userSettings = userSettings
        self.networkMonitor = networkMonitor
        self.coordinator = coordinator
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadData() {
        // Check if AI analysis is enabled in user settings
        guard userSettings.isAIAnalysisEnabled else {
            self.error = AnalysisError.aiAnalysisDisabled
            return
        }
        
        // Check network status if cloud analysis is enabled
        if userSettings.useCloudAnalysis && !networkMonitor.isConnected {
            self.error = NetworkError.noInternetConnection
        }
    }
    
    func navigateToSleepAnalysis() {
        coordinator?.showSleepAnalysis()
    }
    
    func navigateToFeedingAnalysis() {
        coordinator?.showFeedingAnalysis()
    }
    
    func navigateToActivityAnalysis() {
        coordinator?.showActivityAnalysis()
    }
    
    func navigateToPrediction() {
        coordinator?.showPrediction()
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
}

// MARK: - Coordinator Protocol
protocol AnalysisCoordinator: AnyObject {
    func showSleepAnalysis()
    func showFeedingAnalysis()
    func showActivityAnalysis()
    func showPrediction()
}

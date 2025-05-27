import Foundation
import Combine

class CloudSettingsViewModel {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var statusMessage: String? = nil
    @Published var cloudSyncEnabled = false
    @Published var cloudAnalysisEnabled = false
    @Published var apiKey: String = ""
    
    // MARK: - Dependencies
    private let userSettings: UserSettings
    private let apiKeyManager: APIKeyManager
    private let networkMonitor: NetworkMonitor
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(userSettings: UserSettings, apiKeyManager: APIKeyManager, networkMonitor: NetworkMonitor) {
        self.userSettings = userSettings
        self.apiKeyManager = apiKeyManager
        self.networkMonitor = networkMonitor
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadSettings() {
        isLoading = true
        
        // Load cloud sync setting
        cloudSyncEnabled = userSettings.isCloudSyncEnabled
        
        // Load cloud analysis setting
        cloudAnalysisEnabled = userSettings.useCloudAnalysis
        
        // Load API key
        Task {
            do {
                let key = try await apiKeyManager.getAPIKey()
                DispatchQueue.main.async {
                    self.apiKey = key
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "錯誤: 無法載入API密鑰 - \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func setCloudSyncEnabled(_ enabled: Bool) {
        // Check network connection if enabling
        if enabled && !networkMonitor.isConnected {
            statusMessage = "錯誤: 無網絡連接，無法啟用雲端同步"
            cloudSyncEnabled = false
            return
        }
        
        cloudSyncEnabled = enabled
        userSettings.isCloudSyncEnabled = enabled
        
        if enabled {
            statusMessage = "雲端同步已啟用"
        } else {
            statusMessage = "雲端同步已停用"
        }
    }
    
    func setCloudAnalysisEnabled(_ enabled: Bool) {
        // Check network connection if enabling
        if enabled && !networkMonitor.isConnected {
            statusMessage = "錯誤: 無網絡連接，無法啟用雲端AI分析"
            cloudAnalysisEnabled = false
            return
        }
        
        cloudAnalysisEnabled = enabled
        userSettings.useCloudAnalysis = enabled
        
        if enabled {
            statusMessage = "雲端AI分析已啟用"
        } else {
            statusMessage = "雲端AI分析已停用"
        }
    }
    
    func saveSettings(apiKey: String) {
        guard !apiKey.isEmpty else {
            statusMessage = "錯誤: API密鑰不能為空"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await apiKeyManager.saveAPIKey(apiKey)
                
                // Validate API key if cloud features are enabled
                if cloudSyncEnabled || cloudAnalysisEnabled {
                    try await validateAPIKey(apiKey)
                }
                
                DispatchQueue.main.async {
                    self.statusMessage = "設置保存成功"
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "錯誤: 保存設置失敗 - \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Monitor network status changes
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if !isConnected && (self?.cloudSyncEnabled == true || self?.cloudAnalysisEnabled == true) {
                    self?.statusMessage = "警告: 網絡連接已斷開，雲端功能可能不可用"
                }
            }
            .store(in: &cancellables)
    }
    
    private func validateAPIKey(_ key: String) async throws {
        // Simulate API key validation
        // In a real app, this would make an actual API call to validate the key
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // For demo purposes, consider keys starting with "test" as invalid
        if key.lowercased().hasPrefix("test") {
            throw APIKeyError.invalidKey
        }
    }
}

// MARK: - Error Types
enum APIKeyError: Error {
    case invalidKey
    case saveFailed
    case loadFailed
}

extension APIKeyError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "無效的API密鑰"
        case .saveFailed:
            return "保存API密鑰失敗"
        case .loadFailed:
            return "載入API密鑰失敗"
        }
    }
}

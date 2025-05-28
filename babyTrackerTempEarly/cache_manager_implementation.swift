// CacheManager.swift
// 寶寶生活記錄專業版（Baby Tracker）
// 緩存管理實現

import Foundation

/// 緩存管理器，負責緩存API分析結果
class CacheManager {
    // MARK: - 單例
    static let shared = CacheManager()
    private init() {}
    
    // MARK: - 緩存存儲
    private var sleepAnalysisCache: [String: (analysis: SleepAnalysis, timestamp: Date)] = [:]
    private var routineAnalysisCache: [String: (analysis: RoutineAnalysis, timestamp: Date)] = [:]
    private var predictionCache: [String: (prediction: Prediction, timestamp: Date)] = [:]
    
    // MARK: - 緩存有效期（秒）
    private let sleepAnalysisCacheDuration: TimeInterval = 24 * 3600 // 24小時
    private let routineAnalysisCacheDuration: TimeInterval = 12 * 3600 // 12小時
    private let predictionCacheDuration: TimeInterval = 6 * 3600 // 6小時
    
    // MARK: - 睡眠分析緩存
    
    /// 緩存睡眠分析結果
    func cacheSleepAnalysis(_ analysis: SleepAnalysis, for id: String) {
        sleepAnalysisCache[id] = (analysis, Date())
    }
    
    /// 獲取緩存的睡眠分析結果
    func getCachedSleepAnalysis(for id: String) -> SleepAnalysis? {
        guard let cached = sleepAnalysisCache[id],
              Date().timeIntervalSince(cached.timestamp) < sleepAnalysisCacheDuration else {
            return nil
        }
        
        return cached.analysis
    }
    
    // MARK: - 作息分析緩存
    
    /// 緩存作息分析結果
    func cacheRoutineAnalysis(_ analysis: RoutineAnalysis, for id: String) {
        routineAnalysisCache[id] = (analysis, Date())
    }
    
    /// 獲取緩存的作息分析結果
    func getCachedRoutineAnalysis(for id: String) -> RoutineAnalysis? {
        guard let cached = routineAnalysisCache[id],
              Date().timeIntervalSince(cached.timestamp) < routineAnalysisCacheDuration else {
            return nil
        }
        
        return cached.analysis
    }
    
    // MARK: - 預測緩存
    
    /// 緩存預測結果
    func cachePrediction(_ prediction: Prediction, for id: String) {
        predictionCache[id] = (prediction, Date())
    }
    
    /// 獲取緩存的預測結果
    func getCachedPrediction(for id: String) -> Prediction? {
        guard let cached = predictionCache[id],
              Date().timeIntervalSince(cached.timestamp) < predictionCacheDuration else {
            return nil
        }
        
        return cached.prediction
    }
    
    // MARK: - 緩存管理
    
    /// 清理過期緩存
    func cleanupExpiredCache() {
        let now = Date()
        
        // 清理睡眠分析緩存
        sleepAnalysisCache = sleepAnalysisCache.filter {
            now.timeIntervalSince($0.value.timestamp) < sleepAnalysisCacheDuration
        }
        
        // 清理作息分析緩存
        routineAnalysisCache = routineAnalysisCache.filter {
            now.timeIntervalSince($0.value.timestamp) < routineAnalysisCacheDuration
        }
        
        // 清理預測緩存
        predictionCache = predictionCache.filter {
            now.timeIntervalSince($0.value.timestamp) < predictionCacheDuration
        }
    }
    
    /// 獲取緩存統計信息
    func getCacheStatistics() -> (sleepCount: Int, routineCount: Int, predictionCount: Int) {
        cleanupExpiredCache() // 先清理過期緩存
        
        return (
            sleepCount: sleepAnalysisCache.count,
            routineCount: routineAnalysisCache.count,
            predictionCount: predictionCache.count
        )
    }
    
    /// 清除所有緩存
    func clearAllCache() {
        sleepAnalysisCache.removeAll()
        routineAnalysisCache.removeAll()
        predictionCache.removeAll()
    }
}

// MARK: - 模型定義

/// 睡眠分析結果模型
struct SleepAnalysis {
    let id: String
    let quality: Double // 0.0-1.0
    let duration: Double // 分鐘
    let cycles: Int
    let timestamp: Date
    let deepSleepPercentage: Double?
    let remSleepPercentage: Double?
    let lightSleepPercentage: Double?
    let environmentImpact: EnvironmentImpact?
    let recommendations: [String]?
    
    struct EnvironmentImpact {
        let lightImpact: Double // -1.0(負面) 到 1.0(正面)
        let noiseImpact: Double
        let temperatureImpact: Double
    }
}

/// 作息分析結果模型
struct RoutineAnalysis {
    let id: String
    let regularityScore: Double // 0.0-1.0
    let typicalPatterns: [Pattern]
    let timeDistribution: [TimeBlock]
    let timestamp: Date
    let recommendations: [String]?
    
    struct Pattern {
        let name: String
        let frequency: Double // 0.0-1.0
        let activities: [String]
    }
    
    struct TimeBlock {
        let startHour: Int
        let endHour: Int
        let activities: [String: Double] // 活動名稱: 頻率
    }
}

/// 預測結果模型
struct Prediction {
    let id: String
    let nextSleepTime: Date?
    let expectedSleepDuration: Double?
    let nextFeedingTime: Date?
    let confidence: Double // 0.0-1.0
    let timestamp: Date
    let factors: [String: Double]?
}

// SleepPatternAnalyzer.swift
// 寶寶生活記錄專業版（Baby Tracker）- 第三階段：本地AI分析功能
// 睡眠模式分析器實現

import Foundation
import CoreData
import Accelerate

// MARK: - 睡眠模式分析結果
struct SleepPatternResult {
    // 基本統計數據
    let totalSleepHours24h: Double // 24小時內總睡眠時間（小時）
    let daytimeSleepHours: Double // 白天睡眠時間（小時）
    let nighttimeSleepHours: Double // 夜間睡眠時間（小時）
    let averageSleepDuration: Double // 平均單次睡眠時長（小時）
    let averageFallAsleepTime: Date? // 平均入睡時間
    let averageWakeUpTime: Date? // 平均醒來時間
    let nightWakingCount: Double // 夜間平均醒來次數
    let nightWakingDuration: Double // 夜間平均醒來時長（分鐘）
    let sleepEfficiency: Double // 睡眠效率（0-1）
    
    // 睡眠週期估算
    let estimatedSleepCycleMinutes: Double? // 估計的睡眠週期（分鐘）
    
    // 睡眠模式類型
    let sleepPatternType: SleepPatternType
    
    // 睡眠規律性評分（0-100）
    let regularityScore: Int
    
    // 環境因素影響
    let environmentalFactors: [EnvironmentalFactorImpact]
    
    // 睡眠趨勢（過去7天與前7天相比）
    let sleepTrend: SleepTrend
    
    // 分析的時間範圍
    let analyzedDateRange: ClosedRange<Date>
    
    // 分析的記錄數量
    let analyzedRecordsCount: Int
    
    // 分析可信度（0-1）
    let confidenceScore: Double
    
    // 分析時間
    let analysisTimestamp: Date
}

// 睡眠模式類型
enum SleepPatternType: String, CaseIterable {
    case highlyRegular = "highlyRegular" // 高度規律
    case moderatelyRegular = "moderatelyRegular" // 中度規律
    case irregular = "irregular" // 不規律
    case evolving = "evolving" // 正在形成中
    case transitioning = "transitioning" // 正在轉變中
    case insufficient = "insufficient" // 數據不足
    
    var localizedName: String {
        switch self {
        case .highlyRegular:
            return NSLocalizedString("高度規律", comment: "Highly regular sleep pattern")
        case .moderatelyRegular:
            return NSLocalizedString("中度規律", comment: "Moderately regular sleep pattern")
        case .irregular:
            return NSLocalizedString("不規律", comment: "Irregular sleep pattern")
        case .evolving:
            return NSLocalizedString("正在形成中", comment: "Evolving sleep pattern")
        case .transitioning:
            return NSLocalizedString("正在轉變中", comment: "Transitioning sleep pattern")
        case .insufficient:
            return NSLocalizedString("數據不足", comment: "Insufficient data for sleep pattern")
        }
    }
    
    var description: String {
        switch self {
        case .highlyRegular:
            return NSLocalizedString("寶寶的睡眠時間和醒來時間非常規律，有助於建立健康的生理時鐘。", comment: "Highly regular sleep pattern description")
        case .moderatelyRegular:
            return NSLocalizedString("寶寶的睡眠模式有一定規律性，但仍有些波動。", comment: "Moderately regular sleep pattern description")
        case .irregular:
            return NSLocalizedString("寶寶的睡眠時間和醒來時間變化較大，可能需要更一致的睡眠習慣。", comment: "Irregular sleep pattern description")
        case .evolving:
            return NSLocalizedString("寶寶的睡眠模式正在形成中，這在發育過程中很常見。", comment: "Evolving sleep pattern description")
        case .transitioning:
            return NSLocalizedString("寶寶的睡眠模式正在轉變，可能是因為發育里程碑或環境變化。", comment: "Transitioning sleep pattern description")
        case .insufficient:
            return NSLocalizedString("記錄的數據不足以確定睡眠模式，請繼續記錄。", comment: "Insufficient data for sleep pattern description")
        }
    }
}

// 環境因素影響
struct EnvironmentalFactorImpact {
    let factor: EnvironmentalFactor
    let impact: Double // -1.0 (極負面) 到 1.0 (極正面)
    let confidence: Double // 0.0 (無信心) 到 1.0 (完全確信)
    
    var impactDescription: String {
        if impact > 0.5 {
            return NSLocalizedString("顯著提升睡眠質量", comment: "Significantly improves sleep quality")
        } else if impact > 0.2 {
            return NSLocalizedString("略微提升睡眠質量", comment: "Slightly improves sleep quality")
        } else if impact > -0.2 {
            return NSLocalizedString("影響不明顯", comment: "No significant impact")
        } else if impact > -0.5 {
            return NSLocalizedString("略微降低睡眠質量", comment: "Slightly reduces sleep quality")
        } else {
            return NSLocalizedString("顯著降低睡眠質量", comment: "Significantly reduces sleep quality")
        }
    }
    
    var confidenceDescription: String {
        if confidence > 0.8 {
            return NSLocalizedString("高度確信", comment: "High confidence")
        } else if confidence > 0.5 {
            return NSLocalizedString("中度確信", comment: "Medium confidence")
        } else {
            return NSLocalizedString("低度確信", comment: "Low confidence")
        }
    }
}

// 環境因素
enum EnvironmentalFactor: String, CaseIterable {
    case light = "light" // 光線
    case noise = "noise" // 噪音
    case temperature = "temperature" // 溫度
    case humidity = "humidity" // 濕度
    case sleepSurface = "sleepSurface" // 睡眠表面
    case clothing = "clothing" // 衣物
    case feedingBeforeSleep = "feedingBeforeSleep" // 睡前餵食
    case bathBeforeSleep = "bathBeforeSleep" // 睡前洗澡
    
    var localizedName: String {
        switch self {
        case .light:
            return NSLocalizedString("光線", comment: "Light environmental factor")
        case .noise:
            return NSLocalizedString("噪音", comment: "Noise environmental factor")
        case .temperature:
            return NSLocalizedString("溫度", comment: "Temperature environmental factor")
        case .humidity:
            return NSLocalizedString("濕度", comment: "Humidity environmental factor")
        case .sleepSurface:
            return NSLocalizedString("睡眠表面", comment: "Sleep surface environmental factor")
        case .clothing:
            return NSLocalizedString("衣物", comment: "Clothing environmental factor")
        case .feedingBeforeSleep:
            return NSLocalizedString("睡前餵食", comment: "Feeding before sleep environmental factor")
        case .bathBeforeSleep:
            return NSLocalizedString("睡前洗澡", comment: "Bath before sleep environmental factor")
        }
    }
}

// 睡眠趨勢
enum SleepTrend: String, CaseIterable {
    case improving = "improving" // 改善中
    case stable = "stable" // 穩定
    case declining = "declining" // 下降中
    case fluctuating = "fluctuating" // 波動
    case insufficient = "insufficient" // 數據不足
    
    var localizedName: String {
        switch self {
        case .improving:
            return NSLocalizedString("改善中", comment: "Improving sleep trend")
        case .stable:
            return NSLocalizedString("穩定", comment: "Stable sleep trend")
        case .declining:
            return NSLocalizedString("下降中", comment: "Declining sleep trend")
        case .fluctuating:
            return NSLocalizedString("波動", comment: "Fluctuating sleep trend")
        case .insufficient:
            return NSLocalizedString("數據不足", comment: "Insufficient data for sleep trend")
        }
    }
    
    var description: String {
        switch self {
        case .improving:
            return NSLocalizedString("寶寶的睡眠質量和時長正在改善。", comment: "Improving sleep trend description")
        case .stable:
            return NSLocalizedString("寶寶的睡眠模式保持穩定。", comment: "Stable sleep trend description")
        case .declining:
            return NSLocalizedString("寶寶的睡眠質量或時長有所下降，可能需要關注。", comment: "Declining sleep trend description")
        case .fluctuating:
            return NSLocalizedString("寶寶的睡眠模式有較大波動，可能受到發育或環境因素影響。", comment: "Fluctuating sleep trend description")
        case .insufficient:
            return NSLocalizedString("記錄的數據不足以確定睡眠趨勢，請繼續記錄。", comment: "Insufficient data for sleep trend description")
        }
    }
}

// MARK: - 睡眠模式分析器
class SleepPatternAnalyzer {
    // 依賴
    private let sleepRepository: SleepRecordRepository
    
    // 常量
    private let minimumRecordsForAnalysis = 5 // 進行分析所需的最少記錄數
    private let minimumRecordsForCycleEstimation = 10 // 進行睡眠週期估算所需的最少記錄數
    private let minimumRecordsForTrendAnalysis = 14 // 進行趨勢分析所需的最少記錄數
    private let minimumRecordsForEnvironmentalAnalysis = 8 // 進行環境因素分析所需的最少記錄數
    
    private let daytimeStartHour: Int = 6 // 白天開始時間（小時）
    private let daytimeEndHour: Int = 20 // 白天結束時間（小時）
    
    // 初始化
    init(sleepRepository: SleepRecordRepository) {
        self.sleepRepository = sleepRepository
    }
    
    // 分析指定寶寶在特定時間範圍內的睡眠模式
    func analyzeSleepPattern(babyId: String, dateRange: ClosedRange<Date>) async -> Result<SleepPatternResult, Error> {
        do {
            // 獲取睡眠記錄
            let sleepRecordsResult = await sleepRepository.getSleepRecords(babyId: babyId, dateRange: dateRange)
            
            switch sleepRecordsResult {
            case .success(let sleepRecords):
                // 檢查記錄數量是否足夠
                guard sleepRecords.count >= minimumRecordsForAnalysis else {
                    return .success(createInsufficientDataResult(dateRange: dateRange, recordsCount: sleepRecords.count))
                }
                
                // 進行分析
                return .success(analyzeRecords(sleepRecords, dateRange: dateRange))
                
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
    
    // 分析睡眠記錄
    private func analyzeRecords(_ sleepRecords: [SleepRecord], dateRange: ClosedRange<Date>) -> SleepPatternResult {
        // 基本統計數據計算
        let totalSleepHours24h = calculateAverageDailySleepHours(sleepRecords)
        let (daytimeSleepHours, nighttimeSleepHours) = calculateDayNightSleepHours(sleepRecords)
        let averageSleepDuration = calculateAverageSleepDuration(sleepRecords)
        let (averageFallAsleepTime, averageWakeUpTime) = calculateAverageSleepTimes(sleepRecords)
        let (nightWakingCount, nightWakingDuration) = calculateNightWakings(sleepRecords)
        let sleepEfficiency = calculateSleepEfficiency(sleepRecords)
        
        // 睡眠週期估算
        let estimatedSleepCycleMinutes = sleepRecords.count >= minimumRecordsForCycleEstimation ? 
            estimateSleepCycle(sleepRecords) : nil
        
        // 睡眠模式類型判定
        let sleepPatternType = determineSleepPatternType(
            sleepRecords: sleepRecords,
            averageFallAsleepTime: averageFallAsleepTime,
            averageWakeUpTime: averageWakeUpTime
        )
        
        // 睡眠規律性評分
        let regularityScore = calculateRegularityScore(
            sleepRecords: sleepRecords,
            averageFallAsleepTime: averageFallAsleepTime,
            averageWakeUpTime: averageWakeUpTime
        )
        
        // 環境因素影響分析
        let environmentalFactors = sleepRecords.count >= minimumRecordsForEnvironmentalAnalysis ?
            analyzeEnvironmentalFactors(sleepRecords) : []
        
        // 睡眠趨勢分析
        let sleepTrend = sleepRecords.count >= minimumRecordsForTrendAnalysis ?
            analyzeSleepTrend(sleepRecords) : .insufficient
        
        // 計算分析可信度
        let confidenceScore = calculateConfidenceScore(
            recordsCount: sleepRecords.count,
            dateRangeLength: Calendar.current.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day ?? 0
        )
        
        // 創建並返回結果
        return SleepPatternResult(
            totalSleepHours24h: totalSleepHours24h,
            daytimeSleepHours: daytimeSleepHours,
            nighttimeSleepHours: nighttimeSleepHours,
            averageSleepDuration: averageSleepDuration,
            averageFallAsleepTime: averageFallAsleepTime,
            averageWakeUpTime: averageWakeUpTime,
            nightWakingCount: nightWakingCount,
            nightWakingDuration: nightWakingDuration,
            sleepEfficiency: sleepEfficiency,
            estimatedSleepCycleMinutes: estimatedSleepCycleMinutes,
            sleepPatternType: sleepPatternType,
            regularityScore: regularityScore,
            environmentalFactors: environmentalFactors,
            sleepTrend: sleepTrend,
            analyzedDateRange: dateRange,
            analyzedRecordsCount: sleepRecords.count,
            confidenceScore: confidenceScore,
            analysisTimestamp: Date()
        )
    }
    
    // 創建數據不足的結果
    private func createInsufficientDataResult(dateRange: ClosedRange<Date>, recordsCount: Int) -> SleepPatternResult {
        return SleepPatternResult(
            totalSleepHours24h: 0,
            daytimeSleepHours: 0,
            nighttimeSleepHours: 0,
            averageSleepDuration: 0,
            averageFallAsleepTime: nil,
            averageWakeUpTime: nil,
            nightWakingCount: 0,
            nightWakingDuration: 0,
            sleepEfficiency: 0,
            estimatedSleepCycleMinutes: nil,
            sleepPatternType: .insufficient,
            regularityScore: 0,
            environmentalFactors: [],
            sleepTrend: .insufficient,
            analyzedDateRange: dateRange,
            analyzedRecordsCount: recordsCount,
            confidenceScore: 0,
            analysisTimestamp: Date()
        )
    }
    
    // MARK: - 分析方法
    
    // 計算平均每日睡眠時間（小時）
    private func calculateAverageDailySleepHours(_ sleepRecords: [SleepRecord]) -> Double {
        // 按日期分組
        let calendar = Calendar.current
        var sleepHoursByDay: [Date: Double] = [:]
        
        for record in sleepRecords {
            let startDay = calendar.startOfDay(for: record.startTime)
            let duration = record.endTime.timeIntervalSince(record.startTime) / 3600 // 轉換為小時
            
            sleepHoursByDay[startDay, default: 0] += duration
        }
        
        // 計算平均值
        let totalHours = sleepHoursByDay.values.reduce(0, +)
        return sleepHoursByDay.isEmpty ? 0 : totalHours / Double(sleepHoursByDay.count)
    }
    
    // 計算白天和夜間睡眠時間（小時）
    private func calculateDayNightSleepHours(_ sleepRecords: [SleepRecord]) -> (daytime: Double, nighttime: Double) {
        let calendar = Calendar.current
        var daytimeSleepHours = 0.0
        var nighttimeSleepHours = 0.0
        
        for record in sleepRecords {
            let startHour = calendar.component(.hour, from: record.startTime)
            let endHour = calendar.component(.hour, from: record.endTime)
            let duration = record.endTime.timeIntervalSince(record.startTime) / 3600 // 轉換為小時
            
            // 簡化處理：根據開始時間判斷是白天還是夜間睡眠
            if startHour >= daytimeStartHour && startHour < daytimeEndHour {
                daytimeSleepHours += duration
            } else {
                nighttimeSleepHours += duration
            }
        }
        
        // 計算平均值
        let days = Set(sleepRecords.map { Calendar.current.startOfDay(for: $0.startTime) }).count
        let avgDaytimeSleepHours = days > 0 ? daytimeSleepHours / Double(days) : 0
        let avgNighttimeSleepHours = days > 0 ? nighttimeSleepHours / Double(days) : 0
        
        return (avgDaytimeSleepHours, avgNighttimeSleepHours)
    }
    
    // 計算平均單次睡眠時長（小時）
    private func calculateAverageSleepDuration(_ sleepRecords: [SleepRecord]) -> Double {
        let durations = sleepRecords.map { $0.endTime.timeIntervalSince($0.startTime) / 3600 }
        return durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
    }
    
    // 計算平均入睡和醒來時間
    private func calculateAverageSleepTimes(_ sleepRecords: [SleepRecord]) -> (fallAsleep: Date?, wakeUp: Date?) {
        let calendar = Calendar.current
        
        // 將所有時間轉換為當天的時間（忽略日期部分）
        let fallAsleepTimes = sleepRecords.map { record -> DateComponents in
            let components = calendar.dateComponents([.hour, .minute], from: record.startTime)
            return components
        }
        
        let wakeUpTimes = sleepRecords.map { record -> DateComponents in
            let components = calendar.dateComponents([.hour, .minute], from: record.endTime)
            return components
        }
        
        // 計算平均小時和分鐘
        guard !fallAsleepTimes.isEmpty && !wakeUpTimes.isEmpty else {
            return (nil, nil)
        }
        
        // 計算平均入睡時間
        let avgFallAsleepHour = fallAsleepTimes.map { $0.hour ?? 0 }.reduce(0, +) / fallAsleepTimes.
(Content truncated due to size limit. Use line ranges to read in chunks)
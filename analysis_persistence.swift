// analysis_persistence.swift
// 寶寶生活記錄專業版（Baby Tracker）- 整合改進
// 分析結果持久化與歷史記錄實現

import Foundation
import CoreData
import Combine

// MARK: - Analysis Entity Extension (Helper Methods)

/// Analysis實體的擴展，提供便利的創建和更新方法
extension Analysis {
    /// 使用分析結果數據填充實體屬性
    /// - Parameters:
    ///   - context: Core Data上下文
    ///   - baby: 關聯的寶寶實體
    ///   - type: 分析類型
    ///   - resultData: 序列化後的分析結果數據
    ///   - summary: 分析摘要
    ///   - recommendations: 建議內容列表
    ///   - isCloudAnalysis: 是否為雲端分析
    func populate(context: NSManagedObjectContext,
                  baby: Baby,
                  type: AnalysisType,
                  resultData: Data,
                  summary: String?,
                  recommendations: [String],
                  isCloudAnalysis: Bool) {
        self.id = UUID()
        self.baby = baby
        self.type = type.rawValue // 使用枚舉的rawValue
        self.result = resultData
        self.creationDate = Date()
        self.summary = summary
        self.isCloudSource = isCloudAnalysis // 新增屬性，標識來源
        
        // 清除舊的建議（如果有的話）
        if let existingRecommendations = self.recommendations as? Set<Recommendation> {
            existingRecommendations.forEach { context.delete($0) }
        }
        
        // 創建新的建議實體
        recommendations.forEach { content in
            let recommendation = Recommendation(context: context)
            recommendation.populate(analysis: self, content: content)
            self.addToRecommendations(recommendation)
        }
        
        self.updatedAt = Date() // 新增屬性，記錄更新時間
    }
}

/// Recommendation實體的擴展
extension Recommendation {
    /// 使用建議內容填充實體屬性
    /// - Parameters:
    ///   - analysis: 關聯的分析實體
    ///   - content: 建議內容
    func populate(analysis: Analysis, content: String) {
        self.id = UUID()
        self.analysis = analysis
        self.content = content
        self.basis = analysis.summary ?? "N/A" // 暫時使用分析摘要作為依據
        self.creationDate = Date()
        self.status = "new"
    }
}

// MARK: - Analysis Type Raw Value

/// 為AnalysisType添加rawValue以方便存儲
extension AnalysisType {
    var rawValue: String {
        switch self {
        case .sleep:
            return "sleep_pattern"
        case .routine:
            return "routine_pattern"
        case .prediction:
            return "prediction"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "sleep_pattern":
            self = .sleep
        case "routine_pattern":
            self = .routine
        case "prediction":
            self = .prediction
        default:
            return nil
        }
    }
}

// MARK: - Analysis Repository

/// 分析結果倉庫協議
protocol AnalysisRepositoryProtocol {
    /// 保存分析結果
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - type: 分析類型
    ///   - result: 分析結果對象 (需要是Codable)
    ///   - summary: 分析摘要
    ///   - recommendations: 建議列表
    ///   - isCloudAnalysis: 是否為雲端分析
    /// - Returns: 保存成功則返回Analysis實體，否則返回錯誤
    func saveAnalysisResult<T: Codable>(
        babyId: UUID,
        type: AnalysisType,
        result: T,
        summary: String?,
        recommendations: [String],
        isCloudAnalysis: Bool
    ) async -> Result<Analysis, Error>
    
    /// 獲取指定寶寶的分析歷史記錄
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - type: 分析類型 (可選)
    ///   - limit: 限制數量 (可選)
    /// - Returns: 分析歷史記錄列表或錯誤
    func getAnalysisHistory(
        babyId: UUID,
        type: AnalysisType?,
        limit: Int?
    ) async -> Result<[Analysis], Error>
    
    /// 獲取最新的分析結果
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - type: 分析類型
    /// - Returns: 最新的分析結果或錯誤
    func getLatestAnalysis(
        babyId: UUID,
        type: AnalysisType
    ) async -> Result<Analysis?, Error>
    
    /// 刪除分析記錄
    /// - Parameter analysisId: 分析記錄ID
    /// - Returns: 成功或錯誤
    func deleteAnalysis(analysisId: UUID) async -> Result<Void, Error>
}

/// Core Data實現的分析結果倉庫
class CoreDataAnalysisRepository: AnalysisRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func saveAnalysisResult<T: Codable>(
        babyId: UUID,
        type: AnalysisType,
        result: T,
        summary: String?,
        recommendations: [String],
        isCloudAnalysis: Bool
    ) async -> Result<Analysis, Error> {
        let context = coreDataStack.persistentContainer.newBackgroundContext()
        
        return await context.perform { () -> Result<Analysis, Error> in
            do {
                // 查找寶寶實體
                let fetchRequest: NSFetchRequest<Baby> = Baby.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", babyId as CVarArg)
                guard let baby = try context.fetch(fetchRequest).first else {
                    return .failure(RepositoryError.notFound)
                }
                
                // 序列化分析結果
                let encoder = JSONEncoder()
                let resultData = try encoder.encode(result)
                
                // 創建或更新Analysis實體
                // 這裡可以根據需求決定是創建新記錄還是更新舊記錄
                // 目前實現為創建新記錄
                let analysis = Analysis(context: context)
                analysis.populate(
                    context: context,
                    baby: baby,
                    type: type,
                    resultData: resultData,
                    summary: summary,
                    recommendations: recommendations,
                    isCloudAnalysis: isCloudAnalysis
                )
                
                // 保存上下文
                try context.save()
                
                // 返回在主上下文中獲取的對象，確保線程安全
                let mainContextAnalysis = try self.coreDataStack.persistentContainer.viewContext.existingObject(with: analysis.objectID) as! Analysis
                return .success(mainContextAnalysis)
                
            } catch {
                print("保存分析結果失敗: \(error)")
                return .failure(error)
            }
        }
    }
    
    func getAnalysisHistory(
        babyId: UUID,
        type: AnalysisType?,
        limit: Int?
    ) async -> Result<[Analysis], Error> {
        let context = coreDataStack.persistentContainer.viewContext
        
        return await context.perform { () -> Result<[Analysis], Error> in
            do {
                let fetchRequest: NSFetchRequest<Analysis> = Analysis.fetchRequest()
                var predicates: [NSPredicate] = []
                predicates.append(NSPredicate(format: "baby.id == %@", babyId as CVarArg))
                
                if let analysisType = type {
                    predicates.append(NSPredicate(format: "type == %@", analysisType.rawValue))
                }
                
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Analysis.creationDate, ascending: false)]
                
                if let fetchLimit = limit {
                    fetchRequest.fetchLimit = fetchLimit
                }
                
                let analyses = try context.fetch(fetchRequest)
                return .success(analyses)
            } catch {
                print("獲取分析歷史失敗: \(error)")
                return .failure(error)
            }
        }
    }
    
    func getLatestAnalysis(
        babyId: UUID,
        type: AnalysisType
    ) async -> Result<Analysis?, Error> {
        let context = coreDataStack.persistentContainer.viewContext
        
        return await context.perform { () -> Result<Analysis?, Error> in
            do {
                let fetchRequest: NSFetchRequest<Analysis> = Analysis.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "baby.id == %@ AND type == %@", babyId as CVarArg, type.rawValue)
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Analysis.creationDate, ascending: false)]
                fetchRequest.fetchLimit = 1
                
                let analysis = try context.fetch(fetchRequest).first
                return .success(analysis)
            } catch {
                print("獲取最新分析失敗: \(error)")
                return .failure(error)
            }
        }
    }
    
    func deleteAnalysis(analysisId: UUID) async -> Result<Void, Error> {
        let context = coreDataStack.persistentContainer.newBackgroundContext()
        
        return await context.perform { () -> Result<Void, Error> in
            do {
                let fetchRequest: NSFetchRequest<Analysis> = Analysis.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", analysisId as CVarArg)
                
                if let analysisToDelete = try context.fetch(fetchRequest).first {
                    context.delete(analysisToDelete)
                    try context.save()
                    return .success(())
                } else {
                    return .failure(RepositoryError.notFound)
                }
            } catch {
                print("刪除分析記錄失敗: \(error)")
                return .failure(error)
            }
        }
    }
}

// MARK: - Analysis Use Case

/// 分析用例協議
protocol AnalysisUseCaseProtocol {
    /// 保存睡眠分析結果
    func saveSleepAnalysisResult(
        babyId: UUID,
        result: SleepPatternResult
    ) async -> Result<Analysis, Error>
    
    /// 保存作息分析結果
    func saveRoutineAnalysisResult(
        babyId: UUID,
        result: RoutineAnalysisResult
    ) async -> Result<Analysis, Error>
    
    /// 保存預測結果
    func savePredictionResult(
        babyId: UUID,
        result: PredictionResult
    ) async -> Result<Analysis, Error>
    
    /// 獲取分析歷史記錄
    func getAnalysisHistory(
        babyId: UUID,
        type: AnalysisType?,
        limit: Int?
    ) -> AnyPublisher<[AnalysisViewModel], Error>
    
    /// 獲取最新的分析結果視圖模型
    func getLatestAnalysisViewModel(
        babyId: UUID,
        type: AnalysisType
    ) -> AnyPublisher<AnalysisViewModel?, Error>
    
    /// 刪除分析記錄
    func deleteAnalysis(analysisId: UUID) async -> Result<Void, Error>
}

/// 分析用例實現
class AnalysisUseCase: AnalysisUseCaseProtocol {
    private let repository: AnalysisRepositoryProtocol
    
    init(repository: AnalysisRepositoryProtocol = CoreDataAnalysisRepository()) {
        self.repository = repository
    }
    
    func saveSleepAnalysisResult(
        babyId: UUID,
        result: SleepPatternResult
    ) async -> Result<Analysis, Error> {
        return await repository.saveAnalysisResult(
            babyId: babyId,
            type: .sleep,
            result: result,
            summary: result.summary, // 假設SleepPatternResult有summary屬性
            recommendations: result.recommendations,
            isCloudAnalysis: result.isCloudAnalysis
        )
    }
    
    func saveRoutineAnalysisResult(
        babyId: UUID,
        result: RoutineAnalysisResult
    ) async -> Result<Analysis, Error> {
        return await repository.saveAnalysisResult(
            babyId: babyId,
            type: .routine,
            result: result,
            summary: result.summary, // 假設RoutineAnalysisResult有summary屬性
            recommendations: result.recommendations,
            isCloudAnalysis: result.isCloudAnalysis
        )
    }
    
    func savePredictionResult(
        babyId: UUID,
        result: PredictionResult
    ) async -> Result<Analysis, Error> {
        return await repository.saveAnalysisResult(
            babyId: babyId,
            type: .prediction,
            result: result,
            summary: result.summary, // 假設PredictionResult有summary屬性
            recommendations: result.recommendations,
            isCloudAnalysis: result.isCloudPrediction
        )
    }
    
    func getAnalysisHistory(
        babyId: UUID,
        type: AnalysisType?,
        limit: Int?
    ) -> AnyPublisher<[AnalysisViewModel], Error> {
        return Future<[AnalysisViewModel], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(UseCaseError.selfIsNil))
                return
            }
            Task {
                let result = await self.repository.getAnalysisHistory(
                    babyId: babyId,
                    type: type,
                    limit: limit
                )
                switch result {
                case .success(let analyses):
                    let viewModels = analyses.map { AnalysisViewModel(analysis: $0) }
                    promise(.success(viewModels))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getLatestAnalysisViewModel(
        babyId: UUID,
        type: AnalysisType
    ) -> AnyPublisher<AnalysisViewModel?, Error> {
        return Future<AnalysisViewModel?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(UseCaseError.selfIsNil))
                return
            }
            Task {
                let result = await self.repository.getLatestAnalysis(babyId: babyId, type: type)
                switch result {
                case .success(let analysis):
                    let viewModel = analysis.map { AnalysisViewModel(analysis: $0) }
                    promise(.success(viewModel))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAnalysis(analysisId: UUID) async -> Result<Void, Error> {
        return await repository.deleteAnalysis(analysisId: analysisId)
    }
}

// MARK: - Analysis View Model

/// 分析結果視圖模型
struct AnalysisViewModel: Identifiable {
    let id: UUID
    let type: AnalysisType
    let creationDate: Date
    let summary: String?
    let isCloudSource: Bool
    let recommendations: [String]
    
    // 存儲原始數據以便後續解碼
    private let resultData: Data
    
    init(analysis: Analysis) {
        self.id = analysis.id ?? UUID() // 如果ID為nil則生成一個
        self.type = AnalysisType(rawValue: analysis.type ?? "") ?? .sleep // 默認為睡眠分析
        self.creationDate = analysis.creationDate ?? Date()
        self.summary = analysis.summary
        self.isCloudSource = analysis.isCloudSource
        self.resultData = analysis.result ?? Data()
        
        // 提取建議內容
        if let recommendationSet = analysis.recommendations as? Set<Recommendation> {
            self.recommendations = recommendationSet.compactMap { $0.content }.sorted()
        } else {
            self.recommendations = []
        }
    }
    
    /// 解碼特定類型的分析結果
    /// - Parameter type: 要解碼的結果類型
    /// - Returns: 解碼後的結果或nil
    func decodeResult<T: Codable>(as type: T.Type) -> T? {
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: resultData)
    }
    
    /// 格式化的創建日期
    var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
    
    /// 分析來源描述
    var sourceDescription: String {
        return isCloudSource ? NSLocalizedString("雲端", comment: "") : NSLocalizedString("本地", comment: "")
    }
}

// MARK: - AIEngine Integration

/// 擴展AIEngine以集成分析結果保存
extension AIEngine {
    // 注入AnalysisUseCase依賴
    private var analysisUseCase: AnalysisUseCaseProtocol {
        // 在實際應用中，應該通過依賴注入容器來提供
        return AnalysisUseCase()
    }
    
    /// 分析睡眠模式並保存結果
    func analyzeSleepPatternAndSave(
        babyId: UUID,
        dateRange: ClosedRange<Date>
    ) async -> Result<SleepPatternResult, Error> {
        let analysisResult = await analyzeSleepPattern(babyId: babyId.uuidString, dateRange: dateRange)
        
        switch analysisResult {
        case .success(let result):
            // 保存結果
            let saveResult = await analysisUseCase.saveSleepAnalysisResult(babyId: babyId, result: result)
            if case .failure(let saveError) = saveResult {
                print("保存睡眠分析結果失敗: \(saveError)")
                // 即使保存失敗，仍然返回成功的分析結果
            }
            return .success(result)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// 分析作息模式並保存結果
    func analyzeRoutineAndSave(
        babyId: UUID,
        dateRange: ClosedRange<Date>
    ) async -> Result<RoutineAnalysisResult, Error> {
        let analysisResult = await analyzeRoutine(babyId: babyId.uuidString, dateRange: dateRange)
        
        switch analysisResult {
        case .success(let result):
            // 保存結果
            let saveResult = await analysisUseCase.saveRoutineAnalysisResult(babyId: babyId, result: result)
            if case .failure(let saveError) = saveResult {
                print("保存作息分析結果失敗: \(saveError)")
            }
            return .success(result)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// 預測下次睡眠並保存結果
    func predictNextSleepAndSave(babyId: UUID) async -> Result<PredictionResult, Error> {
        let predictionResult = await predictNextSleep(babyId: babyId.uuidString)
        
        switch predictionResult {
        case .success(let result):
            // 保存結果
            let saveResult = await analysisUseCase.savePredictionResult(babyId: babyId, result: result)
            if case .failure(let saveError) = saveResult {
                print("保存預測結果失敗: \(saveError)")
            }
            return .success(result)
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - Data Model Update (Conceptual)

/*
 為了支持分析歷史記錄和來源標識，需要在Core Data模型中對Analysis實體進行修改：
 
 entity Analysis {
     // ... 其他屬性 ...
     attribute isCloudSource: Boolean, default: false // 新增：標識是否為雲端分析結果
     attribute updatedAt: Date, required // 新增：記錄更新時間，用於排序或判斷新鮮度
     
     // 確保 result 屬性類型為 Binary Data
     attribute result: Binary, required
     
     // 確保 type 屬性存儲 AnalysisType 的 rawValue
     attribute type: String, required
     
     // 確保與 Baby 的關係正確設置
     relationship baby: to-one Baby, inverse: analyses, required
     
     // 確保與 Recommendation 的關係正確設置
     relationship recommendations: to-many Recommendation, inverse: analysis, delete-rule: cascade
 }
 
 entity Recommendation {
     // ... 其他屬性 ...
     attribute basis: String, optional // 修改：建議依據可以為可選
     
     // 確保與 Analysis 的關係正確設置
     relationship analysis: to-one Analysis, inverse: recommendations, required
 }
 
 **注意：** 實際修改需要在Xcode的數據模型編輯器中進行，並可能需要創建新的數據模型版本和遷移策略。
 */

// MARK: - Repository Error

enum RepositoryError: Error, LocalizedError {
    case notFound
    case saveFailed(Error?)
    case fetchFailed(Error?)
    case deleteFailed(Error?)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return NSLocalizedString("未找到指定的記錄", comment: "")
        case .saveFailed(let error):
            return String(format: NSLocalizedString("保存失敗：%@", comment: ""), error?.localizedDescription ?? "未知錯誤")
        case .fetchFailed(let error):
            return String(format: NSLocalizedString("獲取失敗：%@", comment: ""), error?.localizedDescription ?? "未知錯誤")
        case .deleteFailed(let error):
            return String(format: NSLocalizedString("刪除失敗：%@", comment: ""), error?.localizedDescription ?? "未知錯誤")
        }
    }
}

// MARK: - UseCase Error

enum UseCaseError: Error, LocalizedError {
    case selfIsNil
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .selfIsNil:
            return NSLocalizedString("內部錯誤：對象已被釋放", comment: "")
        case .invalidInput:
            return NSLocalizedString("輸入無效", comment: "")
        }
    }
}


import Foundation

/// 成長記錄倉庫協議
protocol GrowthRepository {
    /// 獲取寶寶的所有成長記錄
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - completion: 完成回調
    func getGrowthRecords(forBabyId babyId: String, completion: @escaping (Result<[Growth], RepositoryError>) -> Void)
    
    /// 獲取成長記錄
    /// - Parameters:
    ///   - id: 成長記錄ID
    ///   - completion: 完成回調
    func getGrowthRecord(id: String, completion: @escaping (Result<Growth, RepositoryError>) -> Void)
    
    /// 添加成長記錄
    /// - Parameters:
    ///   - growth: 成長記錄
    ///   - completion: 完成回調
    func addGrowthRecord(_ growth: Growth, completion: @escaping (Result<Growth, RepositoryError>) -> Void)
    
    /// 更新成長記錄
    /// - Parameters:
    ///   - growth: 成長記錄
    ///   - completion: 完成回調
    func updateGrowthRecord(_ growth: Growth, completion: @escaping (Result<Growth, RepositoryError>) -> Void)
    
    /// 刪除成長記錄
    /// - Parameters:
    ///   - id: 成長記錄ID
    ///   - completion: 完成回調
    func deleteGrowthRecord(id: String, completion: @escaping (Result<Void, RepositoryError>) -> Void)
    
    /// 獲取寶寶的成長曲線數據
    /// - Parameters:
    ///   - babyId: 寶寶ID
    ///   - completion: 完成回調
    func getGrowthCurveData(forBabyId babyId: String, completion: @escaping (Result<GrowthCurveData, RepositoryError>) -> Void)
}

/// 成長曲線數據
struct GrowthCurveData {
    /// 身高數據
    let heightData: [GrowthDataPoint]
    
    /// 體重數據
    let weightData: [GrowthDataPoint]
    
    /// 頭圍數據
    let headCircumferenceData: [GrowthDataPoint]
    
    /// WHO標準百分位線
    let whoPercentiles: WHOPercentiles
}

/// 成長數據點
struct GrowthDataPoint {
    /// 日期
    let date: Date
    
    /// 值
    let value: Double
    
    /// 百分位
    let percentile: Double
}

/// WHO標準百分位線
struct WHOPercentiles {
    /// 第3百分位
    let p3: [GrowthDataPoint]
    
    /// 第15百分位
    let p15: [GrowthDataPoint]
    
    /// 第50百分位
    let p50: [GrowthDataPoint]
    
    /// 第85百分位
    let p85: [GrowthDataPoint]
    
    /// 第97百分位
    let p97: [GrowthDataPoint]
}

/// 成長記錄倉庫實現
class GrowthRepositoryImpl: GrowthRepository {
    // MARK: - 單例
    
    /// 共享實例
    static let shared = GrowthRepositoryImpl()
    
    // MARK: - 屬性
    
    /// 成長記錄
    private var growthRecords: [Growth] = []
    
    // MARK: - 初始化
    
    /// 初始化方法
    init() {
        // 加載示例數據
        loadSampleData()
    }
    
    // MARK: - GrowthRepository
    
    func getGrowthRecords(forBabyId babyId: String, completion: @escaping (Result<[Growth], RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 過濾成長記錄
            let records = self.growthRecords.filter { $0.babyId == babyId }
            
            // 返回成長記錄
            DispatchQueue.main.async {
                completion(.success(records))
            }
        }
    }
    
    func getGrowthRecord(id: String, completion: @escaping (Result<Growth, RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 查找成長記錄
            if let record = self.growthRecords.first(where: { $0.id == id }) {
                // 返回成長記錄
                DispatchQueue.main.async {
                    completion(.success(record))
                }
            } else {
                // 返回錯誤
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
            }
        }
    }
    
    func addGrowthRecord(_ growth: Growth, completion: @escaping (Result<Growth, RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 檢查是否已存在
            if self.growthRecords.contains(where: { $0.id == growth.id }) {
                // 返回錯誤
                DispatchQueue.main.async {
                    completion(.failure(.duplicateData))
                }
                return
            }
            
            // 添加成長記錄
            self.growthRecords.append(growth)
            
            // 返回成長記錄
            DispatchQueue.main.async {
                completion(.success(growth))
            }
        }
    }
    
    func updateGrowthRecord(_ growth: Growth, completion: @escaping (Result<Growth, RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 查找成長記錄索引
            if let index = self.growthRecords.firstIndex(where: { $0.id == growth.id }) {
                // 更新成長記錄
                self.growthRecords[index] = growth
                
                // 返回成長記錄
                DispatchQueue.main.async {
                    completion(.success(growth))
                }
            } else {
                // 返回錯誤
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
            }
        }
    }
    
    func deleteGrowthRecord(id: String, completion: @escaping (Result<Void, RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 查找成長記錄索引
            if let index = self.growthRecords.firstIndex(where: { $0.id == id }) {
                // 刪除成長記錄
                self.growthRecords.remove(at: index)
                
                // 返回成功
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } else {
                // 返回錯誤
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
            }
        }
    }
    
    func getGrowthCurveData(forBabyId babyId: String, completion: @escaping (Result<GrowthCurveData, RepositoryError>) -> Void) {
        // 模擬異步操作
        DispatchQueue.global().async {
            // 獲取寶寶的成長記錄
            let records = self.growthRecords.filter { $0.babyId == babyId }
            
            // 檢查是否有記錄
            guard !records.isEmpty else {
                // 返回錯誤
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
                return
            }
            
            // 獲取寶寶信息
            DependencyContainer.shared.resolve(BabyRepository.self)?.getBaby(id: babyId) { result in
                switch result {
                case .success(let baby):
                    // 生成成長曲線數據
                    let growthCurveData = self.generateGrowthCurveData(for: baby, with: records)
                    
                    // 返回成長曲線數據
                    DispatchQueue.main.async {
                        completion(.success(growthCurveData))
                    }
                    
                case .failure(let error):
                    // 返回錯誤
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 加載示例數據
    private func loadSampleData() {
        // 創建示例成長記錄
        let calendar = Calendar.current
        let now = Date()
        
        // 寶寶1的成長記錄
        let babyId1 = "1"
        
        let growth1_1 = Growth(
            id: "g1_1",
            babyId: babyId1,
            date: calendar.date(byAdding: .month, value: -6, to: now)!,
            height: 50.0,
            weight: 3.5,
            headCircumference: 35.0
        )
        
        let growth1_2 = Growth(
            id: "g1_2",
            babyId: babyId1,
            date: calendar.date(byAdding: .month, value: -5, to: now)!,
            height: 55.0,
            weight: 4.5,
            headCircumference: 37.0
        )
        
        let growth1_3 = Growth(
            id: "g1_3",
            babyId: babyId1,
            date: calendar.date(byAdding: .month, value: -4, to: now)!,
            height: 58.0,
            weight: 5.5,
            headCircumference: 38.5
        )
        
        let growth1_4 = Growth(
            id: "g1_4",
            babyId: babyId1,
            date: calendar.date(byAdding: .month, value: -3, to: now)!,
            height: 61.0,
            weight: 6.2,
            headCircumference: 39.5
        )
        
        let growth1_5 = Growth(
            id: "g1_5",
            babyId: babyId1,
            date: calendar.date(byAdding: .month, value: -2, to: now)!,
            height: 63.0,
            weight: 6.8,
            headCircumference: 40.5
        )
        
        let growth1_6 = Growth(
            id: "g1_6",
            babyId: babyId1,
            date: calendar.date(byAdding: .month, value: -1, to: now)!,
            height: 65.0,
            weight: 7.2,
            headCircumference: 41.0
        )
        
        // 寶寶2的成長記錄
        let babyId2 = "2"
        
        let growth2_1 = Growth(
            id: "g2_1",
            babyId: babyId2,
            date: calendar.date(byAdding: .month, value: -12, to: now)!,
            height: 50.0,
            weight: 3.3,
            headCircumference: 34.5
        )
        
        let growth2_2 = Growth(
            id: "g2_2",
            babyId: babyId2,
            date: calendar.date(byAdding: .month, value: -9, to: now)!,
            height: 60.0,
            weight: 6.0,
            headCircumference: 39.0
        )
        
        let growth2_3 = Growth(
            id: "g2_3",
            babyId: babyId2,
            date: calendar.date(byAdding: .month, value: -6, to: now)!,
            height: 67.0,
            weight: 8.0,
            headCircumference: 42.0
        )
        
        let growth2_4 = Growth(
            id: "g2_4",
            babyId: babyId2,
            date: calendar.date(byAdding: .month, value: -3, to: now)!,
            height: 72.0,
            weight: 9.5,
            headCircumference: 44.0
        )
        
        // 添加示例成長記錄
        growthRecords = [
            growth1_1, growth1_2, growth1_3, growth1_4, growth1_5, growth1_6,
            growth2_1, growth2_2, growth2_3, growth2_4
        ]
    }
    
    /// 生成成長曲線數據
    /// - Parameters:
    ///   - baby: 寶寶信息
    ///   - records: 成長記錄
    /// - Returns: 成長曲線數據
    private func generateGrowthCurveData(for baby: Baby, with records: [Growth]) -> GrowthCurveData {
        // 排序成長記錄
        let sortedRecords = records.sorted { $0.date < $1.date }
        
        // 生成身高數據
        let heightData = sortedRecords.map { record -> GrowthDataPoint in
            let percentileData = record.getPercentileData(for: baby)
            return GrowthDataPoint(
                date: record.date,
                value: record.height,
                percentile: percentileData.heightPercentile
            )
        }
        
        // 生成體重數據
        let weightData = sortedRecords.map { record -> GrowthDataPoint in
            let percentileData = record.getPercentileData(for: baby)
            return GrowthDataPoint(
                date: record.date,
                value: record.weight,
                percentile: percentileData.weightPercentile
            )
        }
        
        // 生成頭圍數據
        let headCircumferenceData = sortedRecords.map { record -> GrowthDataPoint in
            let percentileData = record.getPercentileData(for: baby)
            return GrowthDataPoint(
                date: record.date,
                value: record.headCircumference,
                percentile: percentileData.headCircumferencePercentile
            )
        }
        
        // 生成WHO標準百分位線
        let whoPercentiles = generateWHOPercentiles(for: baby, from: sortedRecords.first?.date ?? Date(), to: sortedRecords.last?.date ?? Date())
        
        return GrowthCurveData(
            heightData: heightData,
            weightData: weightData,
            headCircumferenceData: headCircumferenceData,
            whoPercentiles: whoPercentiles
        )
    }
    
    /// 生成WHO標準百分位線
    /// - Parameters:
    ///   - baby: 寶寶信息
    ///   - fromDate: 起始日期
    ///   - toDate: 結束日期
    /// - Returns: WHO標準百分位線
    private func generateWHOPercentiles(for baby: Baby, from fromDate: Date, to toDate: Date) -> WHOPercentiles {
        // 這裡應該根據WHO標準數據表生成百分位線
        // 以下為示例數據，實際應用中應該使用完整的WHO數據
        
        // 生成日期範圍
        let calendar = Calendar.current
        let dateRange = calendar.dateComponents([.month], from: fromDate, to: toDate).month ?? 0
        
        // 生成數據點
        var p3: [GrowthDataPoint] = []
        var p15: [GrowthDataPoint] = []
        var p50: [GrowthDataPoint] = []
        var p85: [GrowthDataPoint] = []
        var p97: [GrowthDataPoint] = []
        
        for i in 0...dateRange {
            let date = calendar.date(byAdding: .month, value: i, to: fromDate)!
            
            // 根據性別和月齡生成不同的數據
            if baby.gender == .male {
                p3.append(GrowthDataPoint(date: date, value: 50.0 + Double(i) * 2.0 * 0.85, percentile: 3.0))
                p15.append(GrowthDataPoint(date: date, value: 50.0 + Double(i) * 2.0 * 0.92, percentile: 15.0))
                p50.append(GrowthDataPoint(date: date, value: 50.0 + Double(i) * 2.0, percentile: 50.0))
                p85.append(GrowthDataPoint(date: date, value: 50.0 + Double(i) * 2.0 * 1.08, percentile: 85.0))
                p97.append(GrowthDataPoint(date: date, value: 50.0 + Double(i) * 2.0 * 1.15, percentile: 97.0))
            } else {
                p3.append(GrowthDataPoint(date: date, value: 49.0 + Double(i) * 1.9 * 0.85, percentile: 3.0))
                p15.append(GrowthDataPoint(date: date, value: 49.0 + Double(i) * 1.9 * 0.92, percentile: 15.0))
                p50.append(GrowthDataPoint(date: date, value: 49.0 + Double(i) * 1.9, percentile: 50.0))
                p85.append(GrowthDataPoint(date: date, value: 49.0 + Double(i) * 1.9 * 1.08, percentile: 85.0))
                p97.append(GrowthDataPoint(date: date, value: 49.0 + Double(i) * 1.9 * 1.15, percentile: 97.0))
            }
        }
        
        return WHOPercentiles(p3: p3, p15: p15, p50: p50, p85: p85, p97: p97)
    }
}

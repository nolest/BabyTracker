import Foundation
import Combine

class GrowthChartViewModel {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: Error? = nil
    @Published var chartData: ChartView.ChartData? = nil
    
    // MARK: - Dependencies
    private let growthRepository: GrowthRepository
    private let babyRepository: BabyRepository
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentGrowthType: GrowthType = .height
    private var currentTimeRange: TimeRange = .sixMonths
    private var selectedBabyId: String? = nil
    
    // MARK: - Initialization
    init(growthRepository: GrowthRepository, babyRepository: BabyRepository) {
        self.growthRepository = growthRepository
        self.babyRepository = babyRepository
    }
    
    // MARK: - Public Methods
    func loadData() {
        isLoading = true
        
        // First, get the selected baby ID
        babyRepository.getAllBabies { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let babies):
                // Use the first baby or the selected one
                if let firstBaby = babies.first {
                    self.selectedBabyId = firstBaby.id
                    self.loadGrowthData()
                } else {
                    self.error = RepositoryError.notFound("沒有找到寶寶資料")
                    self.isLoading = false
                }
            case .failure(let error):
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func updateGrowthType(index: Int) {
        guard let type = GrowthType(rawValue: index) else { return }
        self.currentGrowthType = type
        
        // Reload data with new type
        loadGrowthData()
    }
    
    func updateTimeRange(index: Int) {
        guard let range = TimeRange(rawValue: index) else { return }
        self.currentTimeRange = range
        
        // Reload data with new time range
        loadGrowthData()
    }
    
    // MARK: - Private Methods
    private func loadGrowthData() {
        guard let babyId = selectedBabyId else {
            self.error = RepositoryError.notFound("沒有選擇寶寶")
            self.isLoading = false
            return
        }
        
        let dateRange = getDateRange(for: currentTimeRange)
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        
        growthRepository.getGrowthRecords(forBabyId: babyId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let growthRecords):
                // 过滤日期范围内的记录
                let filteredRecords = growthRecords.filter { 
                    startDate <= $0.date && $0.date <= endDate 
                }
                
                // Process growth records based on type
                let processedData = self.processGrowthData(filteredRecords)
                
                self.chartData = processedData
                self.isLoading = false
                self.error = nil
                
            case .failure(let error):
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    private func getDateRange(for timeRange: TimeRange) -> ClosedRange<Date> {
        let now = Date()
        let startDate: Date
        
        switch timeRange {
        case .oneMonth:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        case .threeMonths:
            startDate = Calendar.current.date(byAdding: .month, value: -3, to: now)!
        case .sixMonths:
            startDate = Calendar.current.date(byAdding: .month, value: -6, to: now)!
        case .oneYear:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: now)!
        case .all:
            startDate = Calendar.current.date(byAdding: .year, value: -5, to: now)! // Arbitrary past date
        }
        
        return startDate...now
    }
    
    private func processGrowthData(_ records: [Growth]) -> ChartView.ChartData {
        // Sort records by date
        let sortedRecords = records.sorted { $0.date < $1.date }
        
        // Extract data points based on growth type
        var dataPoints: [ChartView.DataPoint] = []
        var percentile: String? = nil
        var average: String? = nil
        
        for record in sortedRecords {
            let date = record.date
            let value: Double
            
            switch currentGrowthType {
            case .height:
                value = record.height
                if let heightPercentile = record.heightPercentile {
                    percentile = String(format: "%.1f%%", heightPercentile)
                }
                if let avg = calculateAverage(records.map { $0.height }) {
                    average = String(format: "%.1f cm", avg)
                }
            case .weight:
                value = record.weight
                if let weightPercentile = record.weightPercentile {
                    percentile = String(format: "%.1f%%", weightPercentile)
                }
                if let avg = calculateAverage(records.map { $0.weight }) {
                    average = String(format: "%.1f kg", avg)
                }
            case .headCircumference:
                value = record.headCircumference
                if let headCircumferencePercentile = record.headCircumferencePercentile {
                    percentile = String(format: "%.1f%%", headCircumferencePercentile)
                }
                if let avg = calculateAverage(records.map { $0.headCircumference }) {
                    average = String(format: "%.1f cm", avg)
                }
            }
            
            dataPoints.append(ChartView.DataPoint(date: date, value: value))
        }
        
        // Create chart data
        let chartTitle: String
        let yAxisLabel: String
        
        switch currentGrowthType {
        case .height:
            chartTitle = "身高成長曲線"
            yAxisLabel = "身高 (cm)"
        case .weight:
            chartTitle = "體重成長曲線"
            yAxisLabel = "體重 (kg)"
        case .headCircumference:
            chartTitle = "頭圍成長曲線"
            yAxisLabel = "頭圍 (cm)"
        }
        
        return ChartView.ChartData(
            title: chartTitle,
            dataPoints: dataPoints,
            yAxisLabel: yAxisLabel,
            percentile: percentile,
            average: average
        )
    }
    
    private func calculateAverage(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }
    
    // MARK: - Types
    enum GrowthType: Int {
        case height = 0
        case weight = 1
        case headCircumference = 2
    }
    
    enum TimeRange: Int {
        case oneMonth = 0
        case threeMonths = 1
        case sixMonths = 2
        case oneYear = 3
        case all = 4
    }
}

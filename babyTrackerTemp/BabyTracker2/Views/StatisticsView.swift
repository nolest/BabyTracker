import SwiftUI
// import Charts 已移除

struct StatisticsView: View {
    @State private var selectedPeriod: TimePeriod = .day
    @State private var selectedTab: StatisticsTab = .feeding
    
    enum TimePeriod: String, CaseIterable, Identifiable {
        case day = "日"
        case week = "週"
        case month = "月"
        
        var id: String { self.rawValue }
    }
    
    enum StatisticsTab: String, CaseIterable, Identifiable {
        case feeding = "餵食"
        case diaper = "尿布"
        case sleep = "睡眠"
        case growth = "成長"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 時間段選擇器
                Picker("時間段", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 標籤選擇器
                Picker("統計類型", selection: $selectedTab) {
                    ForEach(StatisticsTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // 圖表區域（暫時禁用，使用佔位符）
                VStack(spacing: 20) {
                    // 圖表佔位符
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(height: 250)
                        
                        VStack(spacing: 10) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("圖表功能暫時禁用")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("統計功能將在未來版本中啟用")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 統計摘要
                    VStack(alignment: .leading, spacing: 15) {
                        Text("統計摘要")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // 根據選擇的標籤顯示不同的摘要
                        switch selectedTab {
                        case .feeding:
                            StatisticsSummaryRow(title: "總餵食次數", value: "12次")
                            StatisticsSummaryRow(title: "平均餵食時長", value: "25分鐘")
                            StatisticsSummaryRow(title: "母乳餵食比例", value: "75%")
                            
                        case .diaper:
                            StatisticsSummaryRow(title: "總換尿布次數", value: "8次")
                            StatisticsSummaryRow(title: "濕尿布", value: "5次")
                            StatisticsSummaryRow(title: "髒尿布", value: "3次")
                            
                        case .sleep:
                            StatisticsSummaryRow(title: "總睡眠時間", value: "14小時")
                            StatisticsSummaryRow(title: "平均睡眠時長", value: "2.5小時")
                            StatisticsSummaryRow(title: "最長睡眠時段", value: "4小時")
                            
                        case .growth:
                            StatisticsSummaryRow(title: "當前體重", value: "5.2公斤")
                            StatisticsSummaryRow(title: "當前身高", value: "58厘米")
                            StatisticsSummaryRow(title: "頭圍", value: "38厘米")
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // AI分析按鈕
                Button(action: {
                    // 導航到AI分析視圖
                }) {
                    HStack {
                        Image(systemName: "brain")
                        Text("AI深度分析")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("統計")
        }
    }
}

// 統計摘要行
struct StatisticsSummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}

import SwiftUI

struct SmartScheduleView: View {
    let baby: Baby
    
    @Environment(\.presentationMode) var presentationMode
    @State private var scheduleData: [ScheduleItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack {
            // 日期選擇器
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .onChange(of: selectedDate) { _ in
                generateSchedule()
            }
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Generating smart schedule...")
                        .font(.headline)
                    
                    Text("This may take a moment")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Schedule Generation Error")
                        .font(.title)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Try Again") {
                        generateSchedule()
                    }
                    .padding()
                    .background(Color("PrimaryColor"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            } else if scheduleData.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Schedule Available")
                        .font(.title)
                    
                    Text("Not enough data to generate a smart schedule. Please record more activities.")
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            } else {
                List {
                    ForEach(scheduleData) { item in
                        ScheduleItemRow(item: item)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Smart Schedule")
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
        .onAppear {
            generateSchedule()
        }
    }
    
    private func generateSchedule() {
        isLoading = true
        errorMessage = nil
        
        // 獲取最近的活動數據
        let dataController = DataController.shared
        let recentActivities = dataController.getRecentActivities(for: baby, limit: 50)
        
        if recentActivities.isEmpty {
            isLoading = false
            errorMessage = "Not enough data to generate a schedule. Please record more activities."
            return
        }
        
        // 使用 AI 服務生成排程
        let deepseekService = DeepseekService.shared
        
        // 構建數據摘要
        var dataDict: [String: Any] = [
            "babyName": baby.name ?? "",
            "babyAge": Calendar.current.dateComponents([.day], from: baby.birthDate!, to: Date()).day ?? 0,
            "targetDate": ISO8601DateFormatter().string(from: selectedDate),
            "recentActivities": recentActivities.map { activity -> [String: Any] in
                return [
                    "type": activity.type ?? "",
                    "startTime": ISO8601DateFormatter().string(from: activity.startTime!),
                    "duration": activity.duration
                ]
            }
        ]
        
        // 構建提示詞
        let prompt = """
        Based on the following baby data, generate a detailed daily schedule for \(ISO8601DateFormatter().string(from: selectedDate)):
        \(dataDict)
        
        Please provide:
        1. A complete schedule from morning to night
        2. Specific times for feeding, sleeping, and other activities
        3. Estimated durations for each activity
        4. Any special recommendations for the day
        
        Format the response as a structured schedule with times and activities.
        """
        
        // 發送請求
        deepseekService.sendRequest(prompt: prompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    // 解析回應生成排程項目
                    scheduleData = parseScheduleResponse(response)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func parseScheduleResponse(_ response: String) -> [ScheduleItem] {
        var items: [ScheduleItem] = []
        
        // 簡單的解析邏輯，實際應用中可能需要更複雜的解析
        let lines = response.split(separator: "\n")
        var currentId = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳過空行和標題行
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            // 嘗試匹配時間和活動描述
            if let timeRange = extractTimeRange(from: trimmedLine),
               let description = extractDescription(from: trimmedLine) {
                
                let item = ScheduleItem(
                    id: currentId,
                    timeRange: timeRange,
                    description: description,
                    type: determineActivityType(from: description)
                )
                
                items.append(item)
                currentId += 1
            }
        }
        
        return items.sorted { $0.timeRange.lowerBound < $1.timeRange.lowerBound }
    }
    
    private func extractTimeRange(from line: String) -> ClosedRange<Date>? {
        // 嘗試匹配常見的時間格式，如 "7:00 AM - 8:00 AM" 或 "07:00-08:00"
        let timePatterns = [
            "\\b(\\d{1,2}:\\d{2}\\s*(?:AM|PM)?)\\s*-\\s*(\\d{1,2}:\\d{2}\\s*(?:AM|PM)?)\\b",
            "\\b(\\d{1,2}:\\d{2})\\s*-\\s*(\\d{1,2}:\\d{2})\\b"
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                
                let startRange = Range(match.range(at: 1), in: line)!
                let endRange = Range(match.range(at: 2), in: line)!
                
                let startTimeString = String(line[startRange])
                let endTimeString = String(line[endRange])
                
                // 創建日期組件
                var calendar = Calendar.current
                calendar.timeZone = TimeZone.current
                
                var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                var endComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                
                // 解析時間
                let timeParts = startTimeString.split(separator: ":")
                if timeParts.count >= 2 {
                    startComponents.hour = Int(timeParts[0])
                    
                    let minutePart = timeParts[1].split(separator: " ")[0]
                    startComponents.minute = Int(minutePart)
                    
                    if startTimeString.lowercased().contains("pm") && startComponents.hour! < 12 {
                        startComponents.hour! += 12
                    }
                }
                
                let endTimeParts = endTimeString.split(separator: ":")
                if endTimeParts.count >= 2 {
                    endComponents.hour = Int(endTimeParts[0])
                    
                    let minutePart = endTimeParts[1].split(separator: " ")[0]
                    endComponents.minute = Int(minutePart)
                    
                    if endTimeString.lowercased().contains("pm") && endComponents.hour! < 12 {
                        endComponents.hour! += 12
                    }
                }
                
                if let startDate = calendar.date(from: startComponents),
                   let endDate = calendar.date(from: endComponents) {
                    return startDate...endDate
                }
            }
        }
        
        return nil
    }
    
    private func extractDescription(from line: String) -> String? {
        // 嘗試提取活動描述，通常在時間之後
        let patterns = [
            "\\b\\d{1,2}:\\d{2}\\s*(?:AM|PM)?\\s*-\\s*\\d{1,2}:\\d{2}\\s*(?:AM|PM)?\\s*:?\\s*(.*)",
            "\\b\\d{1,2}:\\d{2}\\s*-\\s*\\d{1,2}:\\d{2}\\s*:?\\s*(.*)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                
                if match.numberOfRanges > 1, let descRange = Range(match.range(at: 1), in: line) {
                    let description = String(line[descRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !description.isEmpty {
                        return description
                    }
                }
            }
        }
        
        // 如果無法通過正則表達式提取，嘗試簡單分割
        let components = line.split(separator: "-", maxSplits: 1)
        if components.count > 1 {
            let possibleDesc = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            if !possibleDesc.isEmpty && !possibleDesc.contains(":") {
                return possibleDesc
            }
        }
        
        // 如果都失敗了，返回整行作為描述
        return line
    }
    
    private func determineActivityType(from description: String) -> String {
        let lowercaseDesc = description.lowercased()
        
        if lowercaseDesc.contains("feed") || lowercaseDesc.contains("breast") || 
           lowercaseDesc.contains("bottle") || lowercaseDesc.contains("milk") || 
           lowercaseDesc.contains("formula") || lowercaseDesc.contains("eat") {
            return "feeding"
        } else if lowercaseDesc.contains("sleep") || lowercaseDesc.contains("nap") || 
                  lowercaseDesc.contains("rest") || lowercaseDesc.contains("bed") {
            return "sleep"
        } else if lowercaseDesc.contains("diaper") || lowercaseDesc.contains("change") || 
                  lowercaseDesc.contains("bathroom") {
            return "diaper"
        } else if lowercaseDesc.contains("play") || lowercaseDesc.contains("activity") || 
                  lowercaseDesc.contains("time") {
            return "play"
        } else if lowercaseDesc.contains("bath") || lowercaseDesc.contains("wash") || 
                  lowercaseDesc.contains("clean") {
            return "bath"
        } else {
            return "other"
        }
    }
}

struct ScheduleItem: Identifiable {
    let id: Int
    let timeRange: ClosedRange<Date>
    let description: String
    let type: String
    
    var startTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timeRange.lowerBound)
    }
    
    var endTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timeRange.upperBound)
    }
    
    var duration: TimeInterval {
        return timeRange.upperBound.timeIntervalSince(timeRange.lowerBound)
    }
    
    var durationString: String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

struct ScheduleItemRow: View {
    let item: ScheduleItem
    
    var body: some View {
        HStack(spacing: 15) {
            // 活動圖標
            Image(systemName: iconForActivity(item.type))
                .font(.title3)
                .foregroundColor(colorForActivity(item.type))
                .frame(width: 40, height: 40)
                .background(colorForActivity(item.type).opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(item.description)
                    .font(.headline)
                
                HStack {
                    Text("\(item.startTimeString) - \(item.endTimeString)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("(\(item.durationString))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func iconForActivity(_ type: String) -> String {
        switch type {
        case "feeding":
            return "bottle.fill"
        case "diaper":
            return "heart.fill"
        case "sleep":
            return "moon.fill"
        case "play":
            return "gamecontroller.fill"
        case "bath":
            return "drop.fill"
        default:
            return "calendar"
        }
    }
    
    private func colorForActivity(_ type: String) -> Color {
        switch type {
        case "feeding":
            return Color("PrimaryColor")
        case "diaper":
            return Color("SecondaryColor")
        case "sleep":
            return Color("AccentColor")
        case "play":
            return Color.green
        case "bath":
            return Color.blue
        default:
            return Color.gray
        }
    }
}

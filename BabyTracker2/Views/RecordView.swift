import SwiftUI

struct RecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedBaby: Baby?
    @State private var babies: [Baby] = []
    @State private var selectedRecordType: String = "feeding"
    
    var body: some View {
        NavigationView {
            VStack {
                // 寶寶選擇器
                if !babies.isEmpty {
                    BabySelectorView(babies: babies, selectedBaby: $selectedBaby)
                        .padding(.horizontal)
                        .padding(.top)
                }
                
                // 記錄類型選擇器
                RecordTypePicker(selectedType: $selectedRecordType)
                    .padding(.top)
                
                // 記錄表單
                ScrollView {
                    VStack {
                        switch selectedRecordType {
                        case "feeding":
                            FeedingRecordForm(baby: selectedBaby)
                        case "diaper":
                            DiaperRecordForm(baby: selectedBaby)
                        case "sleep":
                            SleepRecordForm(baby: selectedBaby)
                        case "growth":
                            GrowthRecordForm(baby: selectedBaby)
                        case "milestone":
                            MilestoneRecordForm(baby: selectedBaby)
                        case "happy_moment":
                            HappyMomentRecordForm(baby: selectedBaby)
                        default:
                            CustomRecordForm(baby: selectedBaby)
                        }
                    }
                    .padding()
                }
                .background(Color("BackgroundColor"))
            }
            .navigationTitle("record".localized)
            .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
            .onAppear(perform: loadData)
        }
    }
    
    private func loadData() {
        let dataController = DataController.shared
        babies = dataController.getAllBabies()
        
        // 如果有寶寶，選擇第一個
        if let firstBaby = babies.first, selectedBaby == nil {
            selectedBaby = firstBaby
        }
        
        // 如果沒有寶寶，創建一個示例寶寶（僅用於開發）
        if babies.isEmpty {
            let newBaby = dataController.addBaby(name: "Baby", birthDate: Date(), gender: "Male")
            babies = [newBaby]
            selectedBaby = newBaby
        }
    }
}

struct RecordTypePicker: View {
    @Binding var selectedType: String
    
    let recordTypes = [
        ("feeding", "bottle.fill", Color("PrimaryColor")),
        ("diaper", "heart.fill", Color("SecondaryColor")),
        ("sleep", "moon.fill", Color("AccentColor")),
        ("growth", "ruler.fill", Color.green),
        ("milestone", "flag.fill", Color.orange),
        ("happy_moment", "camera.fill", Color.purple),
        ("custom", "plus.circle.fill", Color.gray)
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(recordTypes, id: \.0) { type, icon, color in
                    RecordTypeButton(
                        title: type.localized,
                        icon: icon,
                        color: color,
                        isSelected: selectedType == type,
                        action: {
                            selectedType = type
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct RecordTypeButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? color : color.opacity(0.2))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? color : .primary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? color.opacity(0.1) : Color.clear)
            .cornerRadius(10)
        }
    }
}

struct FeedingRecordForm: View {
    let baby: Baby?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var feedingType = "breast_feeding"
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isTimerRunning = false
    @State private var timerStartTime: Date?
    @State private var duration: TimeInterval = 0
    @State private var amount: Double = 0
    @State private var unit = "ml"
    @State private var leftBreastDuration: TimeInterval = 0
    @State private var rightBreastDuration: TimeInterval = 0
    @State private var notes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let feedingTypes = ["breast_feeding", "bottle_feeding", "formula", "solid_food"]
    let units = ["ml", "oz", "g"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("feeding".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            // 餵食類型選擇
            VStack(alignment: .leading, spacing: 10) {
                Text("Feeding Type")
                    .font(.headline)
                
                Picker("", selection: $feedingType) {
                    ForEach(feedingTypes, id: \.self) { type in
                        Text(type.localized).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 時間選擇
            VStack(alignment: .leading, spacing: 10) {
                Text("Time")
                    .font(.headline)
                
                DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                
                if !isTimerRunning {
                    DatePicker("End", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                        .disabled(isTimerRunning)
                }
            }
            
            // 計時器
            VStack(alignment: .leading, spacing: 10) {
                Text("Timer")
                    .font(.headline)
                
                HStack {
                    Text(formatDuration(duration))
                        .font(.title)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    if isTimerRunning {
                        Button(action: stopTimer) {
                            Text("stop".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                    } else {
                        Button(action: startTimer) {
                            Text("start".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color("PrimaryColor"))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 母乳餵食特定字段
            if feedingType == "breast_feeding" {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Breast Feeding")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("left_breast".localized)
                                .font(.subheadline)
                            
                            HStack {
                                Text(formatDuration(leftBreastDuration))
                                    .font(.body)
                                    .monospacedDigit()
                                
                                Stepper("", value: $leftBreastDuration, in: 0...3600, step: 60)
                                    .labelsHidden()
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("right_breast".localized)
                                .font(.subheadline)
                            
                            HStack {
                                Text(formatDuration(rightBreastDuration))
                                    .font(.body)
                                    .monospacedDigit()
                                
                                Stepper("", value: $rightBreastDuration, in: 0...3600, step: 60)
                                    .labelsHidden()
                            }
                        }
                    }
                }
            }
            
            // 瓶餵和配方奶特定字段
            if feedingType == "bottle_feeding" || feedingType == "formula" || feedingType == "solid_food" {
                VStack(alignment: .leading, spacing: 10) {
                    Text("amount".localized)
                        .font(.headline)
                    
                    HStack {
                        TextField("Amount", value: $amount, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Picker("", selection: $unit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                }
            }
            
            // 備註
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes")
                    .font(.headline)
                
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            
            // 保存按鈕
            Button(action: saveRecord) {
                Text("save".localized)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("PrimaryColor"))
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("ok".localized))
            )
        }
    }
    
    private func startTimer() {
        timerStartTime = Date()
        isTimerRunning = true
        
        // 創建一個計時器來更新持續時間
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if let startTime = timerStartTime, isTimerRunning {
                duration = Date().timeIntervalSince(startTime)
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        if let startTime = timerStartTime {
            duration = Date().timeIntervalSince(startTime)
            endTime = Date()
        }
        timerStartTime = nil
    }
    
    private func saveRecord() {
        guard let baby = baby else {
            showAlert = true
            alertMessage = "Please select a baby first"
            return
        }
        
        let dataController = DataController.shared
        let feeding = FeedingActivity(context: viewContext)
        feeding.id = UUID()
        feeding.type = "feeding"
        feeding.feedingType = feedingType
        feeding.startTime = startTime
        feeding.endTime = endTime
        feeding.duration = duration
        feeding.amount = amount
        feeding.unit = unit
        feeding.leftBreastDuration = leftBreastDuration
        feeding.rightBreastDuration = rightBreastDuration
        feeding.notes = notes
        feeding.createdAt = Date()
        feeding.updatedAt = Date()
        feeding.baby = baby
        
        dataController.save()
        
        // 重置表單
        resetForm()
        
        showAlert = true
        alertMessage = "record_saved".localized
    }
    
    private func resetForm() {
        feedingType = "breast_feeding"
        startTime = Date()
        endTime = Date()
        isTimerRunning = false
        timerStartTime = nil
        duration = 0
        amount = 0
        unit = "ml"
        leftBreastDuration = 0
        rightBreastDuration = 0
        notes = ""
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct DiaperRecordForm: View {
    let baby: Baby?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var diaperType = "wet"
    @State private var time = Date()
    @State private var condition = ""
    @State private var notes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let diaperTypes = ["wet", "dirty", "mixed", "dry"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("diaper".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            // 尿布類型選擇
            VStack(alignment: .leading, spacing: 10) {
                Text("Diaper Type")
                    .font(.headline)
                
                Picker("", selection: $diaperType) {
                    ForEach(diaperTypes, id: \.self) { type in
                        Text(type.localized).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 時間選擇
            VStack(alignment: .leading, spacing: 10) {
                Text("Time")
                    .font(.headline)
                
                DatePicker("", selection: $time, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }
            
            // 狀態
            VStack(alignment: .leading, spacing: 10) {
                Text("condition".localized)
                    .font(.headline)
                
                TextField("Condition", text: $condition)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // 備註
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes")
                    .font(.headline)
                
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            
            // 保存按鈕
            Button(action: saveRecord) {
                Text("save".localized)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("SecondaryColor"))
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("ok".localized))
            )
        }
    }
    
    private func saveRecord() {
        guard let baby = baby else {
            showAlert = true
            alertMessage = "Please select a baby first"
            return
        }
        
        let dataController = DataController.shared
        let diaper = DiaperActivity(context: viewContext)
        diaper.id = UUID()
        diaper.type = "diaper"
        diaper.diaperType = diaperType
        diaper.startTime = time
        diaper.condition = condition
        diaper.notes = notes
        diaper.createdAt = Date()
        diaper.updatedAt = Date()
        diaper.baby = baby
        
        dataController.save()
        
        // 重置表單
        resetForm()
        
        showAlert = true
        alertMessage = "record_saved".localized
    }
    
    private func resetForm() {
        diaperType = "wet"
        time = Date()
        condition = ""
        notes = ""
    }
}

struct SleepRecordForm: View {
    let baby: Baby?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isTimerRunning = false
    @State private var timerStartTime: Date?
    @State private var duration: TimeInterval = 0
    @State private var sleepQuality = ""
    @State private var environment = ""
    @State private var notes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let sleepQualities = ["Excellent", "Good", "Fair", "Poor"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("sleep".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            // 時間選擇
            VStack(alignment: .leading, spacing: 10) {
                Text("Time")
                    .font(.headline)
                
                DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                
                if !isTimerRunning {
                    DatePicker("End", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                        .disabled(isTimerRunning)
                }
            }
            
            // 計時器
            VStack(alignment: .leading, spacing: 10) {
                Text("Timer")
                    .font(.headline)
                
                HStack {
                    Text(formatDuration(duration))
                        .font(.title)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    if isTimerRunning {
                        Button(action: stopTimer) {
                            Text("stop".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                    } else {
                        Button(action: startTimer) {
                            Text("start".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color("AccentColor"))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 睡眠質量
            VStack(alignment: .leading, spacing: 10) {
                Text("quality".localized)
                    .font(.headline)
                
                Picker("", selection: $sleepQuality) {
                    Text("Select").tag("")
                    ForEach(sleepQualities, id: \.self) { quality in
                        Text(quality).tag(quality)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 環境
            VStack(alignment: .leading, spacing: 10) {
                Text("environment".localized)
                    .font(.headline)
                
                TextField("Environment", text: $environment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // 備註
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes")
                    .font(.headline)
                
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            
            // 保存按鈕
            Button(action: saveRecord) {
                Text("save".localized)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AccentColor"))
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("ok".localized))
            )
        }
    }
    
    private func startTimer() {
        timerStartTime = Date()
        isTimerRunning = true
        
        // 創建一個計時器來更新持續時間
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if let startTime = timerStartTime, isTimerRunning {
                duration = Date().timeIntervalSince(startTime)
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        if let startTime = timerStartTime {
            duration = Date().timeIntervalSince(startTime)
            endTime = Date()
        }
        timerStartTime = nil
    }
    
    private func saveRecord() {
        guard let baby = baby else {
            showAlert = true
            alertMessage = "Please select a baby first"
            return
        }
        
        let dataController = DataController.shared
        let sleep = SleepActivity(context: viewContext)
        sleep.id = UUID()
        sleep.type = "sleep"
        sleep.startTime = startTime
        sleep.endTime = endTime
        sleep.duration = duration
        sleep.sleepQuality = sleepQuality
        sleep.environment = environment
        sleep.notes = notes
        sleep.createdAt = Date()
        sleep.updatedAt = Date()
        sleep.baby = baby
        
        dataController.save()
        
        // 重置表單
        resetForm()
        
        showAlert = true
        alertMessage = "record_saved".localized
    }
    
    private func resetForm() {
        startTime = Date()
        endTime = Date()
        isTimerRunning = false
        timerStartTime = nil
        duration = 0
        sleepQuality = ""
        environment = ""
        notes = ""
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct GrowthRecordForm: View {
    let baby: Baby?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var date = Date()
    @State private var weight: Double = 0
    @State private var height: Double = 0
    @State private var headCircumference: Double = 0
    @State private var notes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("growth".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            // 日期選擇
            VStack(alignment: .leading, spacing: 10) {
                Text("Date")
                    .font(.headline)
                
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .labelsHidden()
            }
            
            // 體重
            VStack(alignment: .leading, spacing: 10) {
                Text("weight".localized)
                    .font(.headline)
                
                HStack {
                    TextField("Weight", value: $weight, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("kg")
                        .foregroundColor(.gray)
                }
            }
            
            // 身高
            VStack(alignment: .leading, spacing: 10) {
                Text("height".localized)
                    .font(.headline)
                
                HStack {
                    TextField("Height", value: $height, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("cm")
                        .foregroundColor(.gray)
                }
            }
            
            // 頭圍
            VStack(alignment: .leading, spacing: 10) {
                Text("head_circumference".localized)
                    .font(.headline)
                
                HStack {
                    TextField("Head Circumference", value: $headCircumference, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("cm")
                        .foregroundColor(.gray)
                }
            }
            
            // 備註
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes")
                    .font(.headline)
                
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            
            // 保存按鈕
            Button(action: saveRecord) {
                Text("save".localized)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("ok".localized))
            )
        }
    }
    
    private func saveRecord() {
        guard let baby = baby else {
            showAlert = true
            alertMessage = "Please select a baby first"
            return
        }
        
        let dataController = DataController.shared
        let growth = GrowthRecord(context: viewContext)
        growth.id = UUID()
        growth.date = date
        growth.weight = weight
        growth.height = height
        growth.headCircumference = headCircumference
        growth.notes = notes
        growth.createdAt = Date()
        growth.updatedAt = Date()
        growth.baby = baby
        
        dataController.save()
        
        // 重置表單
        resetForm()
        
        showAlert = true
        alertMessage = "record_saved".localized
    }
    
    private func resetForm() {
        date = Date()
        weight = 0
        height = 0
        headCircumference = 0
        notes = ""
    }
}

struct MilestoneRecordForm: View {
    let baby: Baby?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var title = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var category = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let categories = ["Motor", "Language", "Social", "Cognitive", "Other"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("milestone".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            // 標題
            VStack(alignment: .leading, spacing: 10) {
                Text("Title")
                    .font(.headline)
                
                TextField("Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // 日期選擇
            VStack(alignment: .leading, spacing: 10) {
                Text("Date")
                    .font(.headline)
                
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .labelsHidden()
            }
            
            // 類別
            VStack(alignment: .leading, spacing: 10) {
                Text("Category")
                    .font(.headline)
                
                Picker("", selection: $category) {
                    Text("Select").tag("")
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 描述
            VStack(alignment: .leading, spacing: 10) {
                Text("Description")
                    .font(.headline)
                
                TextEditor(text: $description)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            
            // 保存按鈕
            Button(action: saveRecord) {
                Text("save".localized)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("ok".localized))
            )
        }
    }
    
    private func saveRecord() {
        guard let baby = baby else {
            showAlert = true
            alertMessage = "Please select a baby first"
            return
        }
        
        guard !title.isEmpty else {
            showAlert = true
            alertMessage = "Please enter a title"
            return
        }
        
        let dataController = DataController.shared
        let milestone = Milestone(context: viewContext)
        milestone.id = UUID()
        milestone.title = title
        milestone.date = date
        milestone.descriptionText = description
        milestone.category = category
        milestone.createdAt = Date()
        milestone.updatedAt = Date()
        milestone.baby = baby
        
        dataController.save()
        
        // 重置表單
        resetForm()
        
        showAlert = true
        alertMessage = "record_saved".localized
    }
    
    private func resetForm() {
        title = ""
        date = Date()
        description = ""
        category = ""
    }
}

struct HappyMomentRecordForm: View {
    let baby: Baby?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var title = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("happy_moment".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            // 標題
            VStack(alignment: .leading, spacing: 10) {
                Text("Title")
                    .font(.headline)
                
                TextField("Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // 日期選擇
            VStack(alignment: .leading, spacing: 10) {
                Text("Date")
                    .font(.headline)
                
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .labelsHidden()
            }
            
            // 描述
            VStack(alignment: .leading, spacing: 10) {
                Text("Description")
                    .font(.headline)
                
                TextEditor(text: $description)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            
            // 保存按鈕
            Button(action: saveRecord) {
                Text("save".localized)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("ok".localized))
            )
        }
    }
    
    private func saveRecord() {
        guard let baby = baby else {
            showAlert = true
            alertMessage = "Please select a baby first"
            return
        }
        
        guard !title.isEmpty else {
            showAlert = true
            alertMessage = "Please enter a title"
            return
        }
        
        let dataController = DataController.shared
        let happyMoment = HappyMoment(context: viewContext)
        happyMoment.id = UUID()
        happyMoment.title = title
        happyMoment.date = date
        happyMoment.descriptionText = description
        happyMoment.createdAt = Date()
        happyMoment.updatedAt = Date()
        happyMoment.baby = baby
        
        dataController.save()
        
        // 重置表單
        resetForm()
        
        showAlert = true
        alertMessage = "record_saved".localized
    }
    
    private func resetForm() {
        title = ""
        date = Date()
        description = ""
    }
}

struct CustomRecordForm: View {
    let baby: Baby?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var title = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isTimerRunning = false
    @State private var timerStartTime: Date?
    @State private var duration: TimeInterval = 0
    @State private var notes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("custom".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            // 標題
            VStack(alignment: .leading, spacing: 10) {
                Text("Title")
                    .font(.headline)
                
                TextField("Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // 時間選擇
            VStack(alignment: .leading, spacing: 10) {
                Text("Time")
                    .font(.headline)
                
                DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                
                if !isTimerRunning {
                    DatePicker("End", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                        .disabled(isTimerRunning)
                }
            }
            
            // 計時器
            VStack(alignment: .leading, spacing: 10) {
                Text("Timer")
                    .font(.headline)
                
                HStack {
                    Text(formatDuration(duration))
                        .font(.title)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    if isTimerRunning {
                        Button(action: stopTimer) {
                            Text("stop".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                    } else {
                        Button(action: startTimer) {
                            Text("start".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.gray)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 備註
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes")
                    .font(.headline)
                
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            
            // 保存按鈕
            Button(action: saveRecord) {
                Text("save".localized)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("ok".localized))
            )
        }
    }
    
    private func startTimer() {
        timerStartTime = Date()
        isTimerRunning = true
        
        // 創建一個計時器來更新持續時間
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if let startTime = timerStartTime, isTimerRunning {
                duration = Date().timeIntervalSince(startTime)
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        if let startTime = timerStartTime {
            duration = Date().timeIntervalSince(startTime)
            endTime = Date()
        }
        timerStartTime = nil
    }
    
    private func saveRecord() {
        guard let baby = baby else {
            showAlert = true
            alertMessage = "Please select a baby first"
            return
        }
        
        guard !title.isEmpty else {
            showAlert = true
            alertMessage = "Please enter a title"
            return
        }
        
        let dataController = DataController.shared
        let activity = Activity(context: viewContext)
        activity.id = UUID()
        activity.type = title
        activity.startTime = startTime
        activity.endTime = endTime
        activity.duration = duration
        activity.notes = notes
        activity.createdAt = Date()
        activity.updatedAt = Date()
        activity.baby = baby
        
        dataController.save()
        
        // 重置表單
        resetForm()
        
        showAlert = true
        alertMessage = "record_saved".localized
    }
    
    private func resetForm() {
        title = ""
        startTime = Date()
        endTime = Date()
        isTimerRunning = false
        timerStartTime = nil
        duration = 0
        notes = ""
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        RecordView()
            .environment(\.managedObjectContext, DataController.shared.container.viewContext)
            .environmentObject(AppSettings.shared)
    }
}

import SwiftUI
import CoreData

struct AIAnalysisView: View {
    let baby: Baby
    let analysisType: String
    
    @Environment(\.presentationMode) var presentationMode
    @State private var analysisResult: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Analyzing data...")
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
                    
                    Text("Analysis Error")
                        .font(.title)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Try Again") {
                        performAnalysis()
                    }
                    .padding()
                    .background(Color("PrimaryColor"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("AI Analysis Results")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom)
                        
                        Text(analysisResult)
                            .lineSpacing(5)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(getAnalysisTitle())
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
        .onAppear {
            performAnalysis()
        }
    }
    
    private func getAnalysisTitle() -> String {
        switch analysisType {
        case "sleep":
            return "Sleep Analysis"
        case "feeding":
            return "Feeding Analysis"
        case "growth":
            return "Growth Analysis"
        default:
            return "Comprehensive Analysis"
        }
    }
    
    private func performAnalysis() {
        isLoading = true
        errorMessage = nil
        
        let deepseekService = DeepseekService.shared
        
        switch analysisType {
        case "sleep":
            // 獲取睡眠數據
            let request: NSFetchRequest<SleepActivity> = SleepActivity.fetchRequest()
            request.predicate = NSPredicate(format: "baby == %@ AND type == %@", baby, "sleep")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \SleepActivity.startTime, ascending: false)]
            
            do {
                let viewContext = DataController.shared.container.viewContext
                let sleepActivities = try viewContext.fetch(request)
                
                if sleepActivities.isEmpty {
                    isLoading = false
                    errorMessage = "No sleep data available for analysis. Please record some sleep activities first."
                    return
                }
                
                deepseekService.analyzeSleepPattern(sleepData: sleepActivities) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        switch result {
                        case .success(let analysis):
                            analysisResult = analysis
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            } catch {
                isLoading = false
                errorMessage = "Error fetching data: \(error.localizedDescription)"
            }
            
        case "feeding":
            // 獲取餵食數據
            let request: NSFetchRequest<FeedingActivity> = FeedingActivity.fetchRequest()
            request.predicate = NSPredicate(format: "baby == %@ AND type == %@", baby, "feeding")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FeedingActivity.startTime, ascending: false)]
            
            do {
                let viewContext = DataController.shared.container.viewContext
                let feedingActivities = try viewContext.fetch(request)
                
                if feedingActivities.isEmpty {
                    isLoading = false
                    errorMessage = "No feeding data available for analysis. Please record some feeding activities first."
                    return
                }
                
                deepseekService.analyzeFeedingPattern(feedingData: feedingActivities) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        switch result {
                        case .success(let analysis):
                            analysisResult = analysis
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            } catch {
                isLoading = false
                errorMessage = "Error fetching data: \(error.localizedDescription)"
            }
            
        case "growth":
            // 獲取成長數據
            let request: NSFetchRequest<GrowthRecord> = GrowthRecord.fetchRequest()
            request.predicate = NSPredicate(format: "baby == %@", baby)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \GrowthRecord.date, ascending: false)]
            
            do {
                let viewContext = DataController.shared.container.viewContext
                let growthRecords = try viewContext.fetch(request)
                
                if growthRecords.isEmpty {
                    isLoading = false
                    errorMessage = "No growth data available for analysis. Please record some growth measurements first."
                    return
                }
                
                deepseekService.analyzeGrowthData(growthData: growthRecords) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        switch result {
                        case .success(let analysis):
                            analysisResult = analysis
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            } catch {
                isLoading = false
                errorMessage = "Error fetching data: \(error.localizedDescription)"
            }
            
        default:
            // 綜合分析
            deepseekService.generateComprehensiveSuggestions(baby: baby) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let analysis):
                        analysisResult = analysis
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

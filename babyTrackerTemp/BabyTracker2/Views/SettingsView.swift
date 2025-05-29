import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedBaby: Baby?
    @State private var babies: [Baby] = []
    @State private var showingAddBaby = false
    @State private var showingEditBaby = false
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    var body: some View {
        NavigationView {
            List {
                // 寶寶選擇器
                if !babies.isEmpty {
                    Section(header: Text("baby_info".localized)) {
                        ForEach(babies, id: \.id) { baby in
                            BabyRow(baby: baby, isSelected: baby.id == selectedBaby?.id)
                                .onTapGesture {
                                    selectedBaby = baby
                                }
                        }
                        .onDelete(perform: deleteBaby)
                        
                        Button(action: {
                            showingAddBaby = true
                        }) {
                            Label("Add Baby", systemImage: "plus")
                        }
                    }
                } else {
                    Section(header: Text("baby_info".localized)) {
                        Button(action: {
                            showingAddBaby = true
                        }) {
                            Label("Add Baby", systemImage: "plus")
                        }
                    }
                }
                
                // 應用設置
                Section(header: Text("app_settings".localized)) {
                    // 語言設置
                    Picker("language".localized, selection: $appSettings.language) {
                        Text("English").tag("en")
                        Text("繁體中文").tag("zh-Hant")
                        Text("简体中文").tag("zh-Hans")
                    }
                    
                    // 主題設置
                    Toggle("Dark Mode", isOn: $appSettings.isDarkMode)
                    
                    // AI 功能設置
                    Toggle("enable_ai".localized, isOn: $appSettings.aiEnabled)
                }
                
                // 關於
                Section(header: Text("about".localized)) {
                    Button("About BabyTracker") {
                        showingAbout = true
                    }
                    
                    Button("privacy_policy".localized) {
                        showingPrivacyPolicy = true
                    }
                    
                    Button("terms_of_service".localized) {
                        showingTermsOfService = true
                    }
                    
                    HStack {
                        Text("version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("settings".localized)
            .onAppear(perform: loadData)
            .sheet(isPresented: $showingAddBaby) {
                AddBabyView()
            }
            .sheet(isPresented: $showingEditBaby) {
                if let baby = selectedBaby {
                    EditBabyView(baby: baby)
                }
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceView()
            }
        }
    }
    
    private func loadData() {
        let dataController = DataController.shared
        babies = dataController.getAllBabies()
        
        // 如果有寶寶，選擇第一個
        if let firstBaby = babies.first, selectedBaby == nil {
            selectedBaby = firstBaby
        }
    }
    
    private func deleteBaby(at offsets: IndexSet) {
        let dataController = DataController.shared
        
        for index in offsets {
            let baby = babies[index]
            dataController.delete(baby)
            
            // 如果刪除的是當前選中的寶寶，重置選中
            if baby.id == selectedBaby?.id {
                selectedBaby = babies.first
            }
        }
        
        // 重新加載數據
        loadData()
    }
}

struct BabyRow: View {
    let baby: Baby
    let isSelected: Bool
    
    var body: some View {
        HStack {
            if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color("PrimaryColor"))
            }
            
            VStack(alignment: .leading) {
                Text(baby.name ?? "Baby")
                    .font(.headline)
                
                if let birthDate = baby.birthDate {
                    Text(formatAge(from: birthDate))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(Color("PrimaryColor"))
            }
        }
    }
    
    private func formatAge(from date: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year, .month, .day], from: date, to: Date())
        
        if let years = ageComponents.year, years > 0 {
            return "\(years) year\(years > 1 ? "s" : "") old"
        } else if let months = ageComponents.month, months > 0 {
            return "\(months) month\(months > 1 ? "s" : "") old"
        } else if let days = ageComponents.day {
            return "\(days) day\(days > 1 ? "s" : "") old"
        }
        
        return "Just born"
    }
}

struct AddBabyView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender = "Male"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Baby Information")) {
                    TextField("name".localized, text: $name)
                    
                    DatePicker("birth_date".localized, selection: $birthDate, displayedComponents: [.date])
                    
                    Picker("gender".localized, selection: $gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender.localized).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Add Baby")
            .navigationBarItems(
                leading: Button("cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("save".localized) {
                    saveBaby()
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertMessage),
                    dismissButton: .default(Text("ok".localized))
                )
            }
        }
    }
    
    private func saveBaby() {
        guard !name.isEmpty else {
            showAlert = true
            alertMessage = "Please enter a name"
            return
        }
        
        let dataController = DataController.shared
        _ = dataController.addBaby(name: name, birthDate: birthDate, gender: gender)
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditBabyView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    let baby: Baby
    
    @State private var name: String
    @State private var birthDate: Date
    @State private var gender: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let genders = ["Male", "Female", "Other"]
    
    init(baby: Baby) {
        self.baby = baby
        _name = State(initialValue: baby.name ?? "")
        _birthDate = State(initialValue: baby.birthDate ?? Date())
        _gender = State(initialValue: baby.gender ?? "Male")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Baby Information")) {
                    TextField("name".localized, text: $name)
                    
                    DatePicker("birth_date".localized, selection: $birthDate, displayedComponents: [.date])
                    
                    Picker("gender".localized, selection: $gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender.localized).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Edit Baby")
            .navigationBarItems(
                leading: Button("cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("save".localized) {
                    updateBaby()
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertMessage),
                    dismissButton: .default(Text("ok".localized))
                )
            }
        }
    }
    
    private func updateBaby() {
        guard !name.isEmpty else {
            showAlert = true
            alertMessage = "Please enter a name"
            return
        }
        
        baby.name = name
        baby.birthDate = birthDate
        baby.gender = gender
        baby.updatedAt = Date()
        
        let dataController = DataController.shared
        dataController.save()
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("About BabyTracker")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("BabyTracker is a comprehensive baby tracking app designed to help parents monitor their baby's daily activities, growth, and development.")
                        .padding(.bottom, 10)
                    
                    Text("Key Features:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        FeatureRow(icon: "house.fill", title: "Home Dashboard", description: "Quick overview of your baby's recent activities and status")
                        FeatureRow(icon: "square.and.pencil", title: "Activity Recording", description: "Track feeding, diaper changes, sleep, growth, and more")
                        FeatureRow(icon: "chart.bar.fill", title: "Statistics", description: "Visualize patterns and trends in your baby's activities")
                        FeatureRow(icon: "brain", title: "AI Analysis", description: "Get personalized insights and suggestions based on your baby's data")
                    }
                    .padding(.bottom, 10)
                    
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("© 2025 BabyTracker. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color("PrimaryColor"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("Effective Date: May 28, 2025")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    Text("At BabyTracker, we take your privacy seriously. This Privacy Policy explains how we collect, use, and protect your personal information when you use our application.")
                        .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Information We Collect")
                        
                        Text("We collect information that you provide directly to us, such as your baby's name, birth date, gender, and the activities you record (feeding, diaper changes, sleep, growth measurements, etc.).")
                        
                        Text("All of this information is stored locally on your device. We do not collect or store this information on our servers.")
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "AI Features")
                        
                        Text("If you enable AI features, we use the Deepseek API to provide personalized insights and suggestions. When using these features, your data is sent to Deepseek's servers for processing. We only send anonymized data that cannot be traced back to you or your baby.")
                        
                        Text("You can disable AI features at any time in the app settings.")
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Data Security")
                        
                        Text("We implement appropriate technical and organizational measures to protect your personal information against unauthorized or unlawful processing, accidental loss, destruction, or damage.")
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Changes to This Privacy Policy")
                        
                        Text("We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the effective date.")
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Contact Us")
                        
                        Text("If you have any questions about this Privacy Policy, please contact us at privacy@babytracker.com.")
                    }
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct SectionTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.vertical, 5)
    }
}

struct TermsOfServiceView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("Effective Date: May 28, 2025")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    Text("Please read these Terms of Service carefully before using the BabyTracker application.")
                        .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Acceptance of Terms")
                        
                        Text("By accessing or using BabyTracker, you agree to be bound by these Terms. If you disagree with any part of the terms, you may not access the application.")
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Use License")
                        
                        Text("Permission is granted to use BabyTracker for personal, non-commercial purposes. This license does not include the right to modify, reverse engineer, or create derivative works based on BabyTracker.")
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Disclaimer")
                        
                        Text("BabyTracker is provided \"as is\" without warranties of any kind, either express or implied. We do not warrant that the application will be error-free or uninterrupted.")
                        
                        Text("The information provided by BabyTracker, including AI-generated insights, is for informational purposes only and should not replace professional medical advice.")
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Limitation of Liability")
                        
                        Text("In no event shall BabyTracker be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or relating to your use of the application.")
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Changes to Terms")
                        
                        Text("We reserve the right to modify these terms at any time. We will notify you of any changes by posting the new Terms of Service on this page and updating the effective date.")
                    }
                    .padding(.bottom, 10)
                    
                    Group {
                        SectionTitle(title: "Contact Us")
                        
                        Text("If you have any questions about these Terms, please contact us at terms@babytracker.com.")
                    }
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, DataController.shared.container.viewContext)
            .environmentObject(AppSettings.shared)
    }
}

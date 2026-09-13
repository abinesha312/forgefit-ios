import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @StateObject private var healthKit = HealthKitService()
    
    @State private var showingEditProfile = false
    @State private var showingLogWeight = false
    
    var profile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let profile = profile {
                    Section("Profile") {
                        ProfileInfoRow(title: "Name", value: profile.name)
                        if let sex = profile.sex {
                            ProfileInfoRow(title: "Sex", value: sex)
                        }
                        ProfileInfoRow(title: "Age", value: "\(Calendar.current.component(.year, from: Date()) - profile.birthYear)")
                        ProfileInfoRow(title: "Height", value: "\(Int(profile.heightCm)) cm")
                        ProfileInfoRow(title: "Weight", value: "\(Int(profile.weightKg)) kg")
                        
                        Button("Log Weight") {
                            showingLogWeight = true
                        }
                    }
                    
                    Section("Goals & Preferences") {
                        ProfileInfoRow(title: "Goal", value: profile.bodyGoal.rawValue)
                        ProfileInfoRow(title: "Experience", value: profile.experienceLevel.rawValue)
                        ProfileInfoRow(title: "Equipment", value: profile.equipment.rawValue)
                        ProfileInfoRow(title: "Training Days", value: "\(profile.trainingDaysPerWeek) days/week")
                        ProfileInfoRow(title: "Session Length", value: "\(profile.sessionLengthMinutes) minutes")
                    }
                    
                    Section("Health") {
                        HStack {
                            Label("Apple Health", systemImage: "heart.fill")
                            Spacer()
                            if healthKit.isAuthorized {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Button("Connect") {
                                    Task {
                                        await healthKit.requestAuthorization()
                                    }
                                }
                            }
                        }
                    }
                    
                    Section {
                        Button("Edit Profile") {
                            showingEditProfile = true
                        }
                    }
                    
                    Section {
                        Button("About ForgeFit", action: {})
                        Button("Privacy Policy", action: {})
                    }
                    
                    Section("Danger Zone") {
                        Button("Reset All Data", role: .destructive) {
                            resetAllData()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                if let profile = profile {
                    EditProfileView(profile: profile)
                }
            }
            .sheet(isPresented: $showingLogWeight) {
                LogWeightView()
            }
        }
    }
    
    func resetAllData() {
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $profile.name)
                    
                    Picker("Sex", selection: $profile.sex) {
                        Text("Not specified").tag(nil as String?)
                        Text("Male").tag("Male" as String?)
                        Text("Female").tag("Female" as String?)
                        Text("Other").tag("Other" as String?)
                    }
                }
                
                Section("Body") {
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", value: $profile.heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", value: $profile.weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Goals") {
                    Picker("Body Goal", selection: $profile.bodyGoal) {
                        ForEach(BodyGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                    
                    Picker("Experience", selection: $profile.experienceLevel) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    
                    Picker("Equipment", selection: $profile.equipment) {
                        ForEach(Equipment.allCases, id: \.self) { equip in
                            Text(equip.rawValue).tag(equip)
                        }
                    }
                }
                
                Section("Training") {
                    Picker("Days per Week", selection: $profile.trainingDaysPerWeek) {
                        ForEach(2...6, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                    
                    HStack {
                        Text("Session Length")
                        Spacer()
                        TextField("minutes", value: $profile.sessionLengthMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LogWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var healthKit = HealthKitService()
    
    @State private var weightKg: Double = 70
    @State private var date = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Weight") {
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("kg", value: $weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let log = WeightLog(weightKg: weightKg, date: date, notes: notes.isEmpty ? nil : notes)
                        modelContext.insert(log)
                        try? modelContext.save()
                        
                        Task {
                            await healthKit.saveBodyWeight(weightKg, date: date)
                        }
                        
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}

import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @StateObject private var healthKit = HealthKitService()
    
    @State private var currentStep = 0
    @State private var name = ""
    @State private var sex: String? = nil
    @State private var birthYear = Calendar.current.component(.year, from: Date()) - 25
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var bodyGoal: BodyGoal = .generalFitness
    @State private var experienceLevel: ExperienceLevel = .beginner
    @State private var equipment: Equipment = .fullGym
    @State private var trainingDaysPerWeek = 3
    @State private var sessionLengthMinutes = 60
    
    let totalSteps = 9
    
    var body: some View {
        VStack {
            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                .padding()
            
            TabView(selection: $currentStep) {
                WelcomeStep()
                    .tag(0)
                
                NameStep(name: $name)
                    .tag(1)
                
                SexStep(sex: $sex)
                    .tag(2)
                
                BirthYearStep(birthYear: $birthYear)
                    .tag(3)
                
                HeightStep(heightCm: $heightCm)
                    .tag(4)
                
                WeightStep(weightKg: $weightKg)
                    .tag(5)
                
                GoalStep(bodyGoal: $bodyGoal)
                    .tag(6)
                
                ExperienceStep(experienceLevel: $experienceLevel, equipment: $equipment)
                    .tag(7)
                
                TrainingPreferencesStep(trainingDaysPerWeek: $trainingDaysPerWeek, sessionLengthMinutes: $sessionLengthMinutes)
                    .tag(8)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button(currentStep == totalSteps - 1 ? "Finish" : "Next") {
                    if currentStep == totalSteps - 1 {
                        finishOnboarding()
                    } else {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
            .padding()
        }
        .task {
            await healthKit.requestAuthorization()
            if let weight = await healthKit.fetchBodyWeight() {
                weightKg = weight
            }
            if let height = await healthKit.fetchHeight() {
                heightCm = height
            }
        }
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 1: return !name.isEmpty
        default: return true
        }
    }
    
    func finishOnboarding() {
        let profile = UserProfile(
            name: name,
            sex: sex,
            birthYear: birthYear,
            heightCm: heightCm,
            weightKg: weightKg,
            bodyGoal: bodyGoal,
            experienceLevel: experienceLevel,
            equipment: equipment,
            trainingDaysPerWeek: trainingDaysPerWeek,
            sessionLengthMinutes: sessionLengthMinutes
        )
        
        modelContext.insert(profile)
        try? modelContext.save()
        
        appState.hasCompletedOnboarding = true
    }
}

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("💪")
                .font(.system(size: 80))
            Text("Welcome to ForgeFit")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Your personal gym workout tracker")
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

struct NameStep: View {
    @Binding var name: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your name?")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Enter your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct SexStep: View {
    @Binding var sex: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sex / Gender")
                .font(.title)
                .fontWeight(.bold)
            
            Text("(Optional)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Button(action: { sex = "Male" }) {
                    HStack {
                        Text("Male")
                        Spacer()
                        if sex == "Male" {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .background(sex == "Male" ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button(action: { sex = "Female" }) {
                    HStack {
                        Text("Female")
                        Spacer()
                        if sex == "Female" {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .background(sex == "Female" ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button(action: { sex = "Other" }) {
                    HStack {
                        Text("Other / Prefer not to say")
                        Spacer()
                        if sex == "Other" {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .background(sex == "Other" ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct BirthYearStep: View {
    @Binding var birthYear: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Birth Year")
                .font(.title)
                .fontWeight(.bold)
            
            Picker("Birth Year", selection: $birthYear) {
                ForEach((1940...2010).reversed(), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
            
            Text("Age: \(Calendar.current.component(.year, from: Date()) - birthYear)")
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct HeightStep: View {
    @Binding var heightCm: Double
    @State private var useFeet = false
    
    var heightFeet: Int {
        Int(heightCm / 30.48)
    }
    
    var heightInches: Int {
        Int((heightCm / 2.54).truncatingRemainder(dividingBy: 12))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Height")
                .font(.title)
                .fontWeight(.bold)
            
            Picker("Unit", selection: $useFeet) {
                Text("cm").tag(false)
                Text("ft/in").tag(true)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if useFeet {
                HStack {
                    VStack {
                        Text("\(heightFeet) ft")
                        Slider(value: Binding(
                            get: { Double(heightFeet) },
                            set: { heightCm = $0 * 30.48 + Double(heightInches) * 2.54 }
                        ), in: 4...7, step: 1)
                    }
                    VStack {
                        Text("\(heightInches) in")
                        Slider(value: Binding(
                            get: { Double(heightInches) },
                            set: { heightCm = Double(heightFeet) * 30.48 + $0 * 2.54 }
                        ), in: 0...11, step: 1)
                    }
                }
                .padding()
            } else {
                Text("\(Int(heightCm)) cm")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Slider(value: $heightCm, in: 120...220, step: 1)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}

struct WeightStep: View {
    @Binding var weightKg: Double
    @State private var usePounds = false
    
    var weightLbs: Double {
        weightKg * 2.20462
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Weight")
                .font(.title)
                .fontWeight(.bold)
            
            Picker("Unit", selection: $usePounds) {
                Text("kg").tag(false)
                Text("lbs").tag(true)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if usePounds {
                Text("\(Int(weightLbs)) lbs")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Slider(value: Binding(
                    get: { weightLbs },
                    set: { weightKg = $0 / 2.20462 }
                ), in: 66...440, step: 1)
                .padding()
            } else {
                Text("\(Int(weightKg)) kg")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Slider(value: $weightKg, in: 30...200, step: 1)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}

struct GoalStep: View {
    @Binding var bodyGoal: BodyGoal
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Your Goal")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(BodyGoal.allCases, id: \.self) { goal in
                    Button(action: { bodyGoal = goal }) {
                        HStack {
                            Text(goal.rawValue)
                            Spacer()
                            if bodyGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .padding()
                        .background(bodyGoal == goal ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct ExperienceStep: View {
    @Binding var experienceLevel: ExperienceLevel
    @Binding var equipment: Equipment
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Experience & Equipment")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Experience Level")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    Button(action: { experienceLevel = level }) {
                        HStack {
                            Text(level.rawValue)
                            Spacer()
                            if experienceLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .padding()
                        .background(experienceLevel == level ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            
            Text("Equipment Access")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 12) {
                ForEach(Equipment.allCases, id: \.self) { equip in
                    Button(action: { equipment = equip }) {
                        HStack {
                            Text(equip.rawValue)
                            Spacer()
                            if equipment == equip {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .padding()
                        .background(equipment == equip ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TrainingPreferencesStep: View {
    @Binding var trainingDaysPerWeek: Int
    @Binding var sessionLengthMinutes: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Training Schedule")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Days per Week: \(trainingDaysPerWeek)")
                    .font(.headline)
                
                Picker("Days", selection: $trainingDaysPerWeek) {
                    ForEach(2...6, id: \.self) { day in
                        Text("\(day) days").tag(day)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Session Length: \(sessionLengthMinutes) minutes")
                    .font(.headline)
                
                Slider(value: Binding(
                    get: { Double(sessionLengthMinutes) },
                    set: { sessionLengthMinutes = Int($0) }
                ), in: 30...120, step: 15)
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppState())
}

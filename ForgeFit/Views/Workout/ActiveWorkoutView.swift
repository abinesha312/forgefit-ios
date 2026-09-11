import SwiftUI
import SwiftData

struct StartWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let routine: WorkoutPlan.DayRoutine
    
    var body: some View {
        VStack(spacing: 20) {
            Text(routine.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(routine.exercises.count) exercises")
                .foregroundStyle(.secondary)
            
            List(routine.exercises, id: \.exercise.id) { planned in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(planned.exercise.name)
                            .font(.headline)
                        Text("\(planned.sets) sets × \(planned.repsMin)-\(planned.repsMax) reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(planned.restSeconds)s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button(action: startWorkout) {
                HStack {
                    Spacer()
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Start Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func startWorkout() {
        let session = WorkoutSession(routineName: routine.name)
        
        for (index, planned) in routine.exercises.enumerated() {
            let workoutExercise = WorkoutExercise(
                exerciseId: planned.exercise.id,
                exerciseName: planned.exercise.name,
                orderIndex: index
            )
            session.exercises.append(workoutExercise)
        }
        
        modelContext.insert(session)
        try? modelContext.save()
        
        appState.currentWorkoutSession = session
        dismiss()
    }
}

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @StateObject private var healthKit = HealthKitService()
    
    @State private var currentExerciseIndex = 0
    @State private var startTime = Date()
    @State private var showingFinishAlert = false
    
    var session: WorkoutSession? {
        appState.currentWorkoutSession
    }
    
    var currentExercise: WorkoutExercise? {
        guard let session = session, currentExerciseIndex < session.exercises.count else {
            return nil
        }
        return session.exercises[currentExerciseIndex]
    }
    
    var body: some View {
        NavigationStack {
            if let session = session, let exercise = currentExercise {
                VStack(spacing: 0) {
                    progressBar
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            exerciseInfo(exercise)
                            
                            setsSection(exercise)
                            
                            addSetButton(exercise)
                            
                            notesSection(exercise)
                        }
                        .padding()
                    }
                    
                    navigationButtons
                }
                .navigationTitle(session.routineName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Finish") {
                            showingFinishAlert = true
                        }
                    }
                }
                .alert("Finish Workout?", isPresented: $showingFinishAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Finish", role: .destructive) {
                        finishWorkout()
                    }
                } message: {
                    Text("Are you sure you want to finish this workout?")
                }
            } else {
                Text("No active workout")
            }
        }
    }
    
    var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 4)
    }
    
    var progress: Double {
        guard let session = session else { return 0 }
        return Double(currentExerciseIndex) / Double(session.exercises.count)
    }
    
    func exerciseInfo(_ exercise: WorkoutExercise) -> some View {
        VStack(spacing: 12) {
            Text(exercise.exerciseName)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Exercise \(currentExerciseIndex + 1) of \(session?.exercises.count ?? 0)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    func setsSection(_ exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sets")
                .font(.headline)
            
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                SetRowView(set: set, setNumber: index + 1)
            }
        }
    }
    
    func addSetButton(_ exercise: WorkoutExercise) -> some View {
        Button(action: {
            let newSet = ExerciseSet(setNumber: exercise.sets.count + 1)
            exercise.sets.append(newSet)
            try? modelContext.save()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Set")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(10)
        }
    }
    
    func notesSection(_ exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            
            TextField("Add notes...", text: Binding(
                get: { exercise.notes ?? "" },
                set: { exercise.notes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(3...6)
        }
    }
    
    var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentExerciseIndex > 0 {
                Button(action: {
                    withAnimation {
                        currentExerciseIndex -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentExerciseIndex < (session?.exercises.count ?? 0) - 1 {
                Button(action: {
                    withAnimation {
                        currentExerciseIndex += 1
                    }
                }) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    func finishWorkout() {
        guard let session = session else { return }
        
        session.duration = Date().timeIntervalSince(startTime)
        session.completed = true
        
        try? modelContext.save()
        
        Task {
            await healthKit.saveWorkout(session: session)
        }
        
        appState.currentWorkoutSession = nil
    }
}

struct SetRowView: View {
    @Bindable var set: ExerciseSet
    let setNumber: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(setNumber)")
                .font(.headline)
                .frame(width: 30)
            
            VStack(spacing: 4) {
                Text("Weight")
                    .font(.caption)
                TextField("kg", value: $set.weight, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
            }
            
            VStack(spacing: 4) {
                Text("Reps")
                    .font(.caption)
                TextField("reps", value: $set.reps, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            
            Toggle("WU", isOn: $set.isWarmup)
                .labelsHidden()
                .frame(width: 50)
        }
        .padding()
        .background(set.isWarmup ? Color.orange.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, configurations: config)
    
    return ActiveWorkoutView()
        .environmentObject(AppState())
        .modelContainer(container)
}

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomRoutine.createdAt, order: .reverse) private var customRoutines: [CustomRoutine]
    
    @StateObject private var exerciseLibrary = ExerciseLibrary()
    @State private var showingCreateRoutine = false
    
    var builtInRoutines: [String] = [
        "Push/Pull/Legs",
        "Upper/Lower",
        "Full Body",
        "Beginner Strength",
        "Hypertrophy",
        "Fat Loss Circuit"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Built-In Programs")
                                .font(.headline)
                            
                            ForEach(builtInRoutines, id: \.self) { routine in
                                RoutineCard(name: routine, isBuiltIn: true)
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("My Routines")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showingCreateRoutine = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }
                        
                        if customRoutines.isEmpty {
                            Text("No custom routines yet")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(customRoutines) { routine in
                                NavigationLink(destination: RoutineDetailView(routine: routine)) {
                                    RoutineCard(name: routine.name, isBuiltIn: false)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Workouts")
            .sheet(isPresented: $showingCreateRoutine) {
                CreateRoutineView()
            }
        }
    }
}

struct RoutineCard: View {
    let name: String
    let isBuiltIn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                if isBuiltIn {
                    Text("Built-In")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct RoutineDetailView: View {
    let routine: CustomRoutine
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(routine.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(routine.split.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let notes = routine.notes {
                    Text(notes)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Divider()
                
                Text("Exercises")
                    .font(.headline)
                
                ForEach(routine.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.exerciseName)
                                .font(.headline)
                            Text("\(exercise.targetSets) sets × \(exercise.targetRepsDisplay) reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(exercise.restSeconds)s rest")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Routine")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreateRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var split: WorkoutSplit = .custom
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Info") {
                    TextField("Name", text: $name)
                    
                    Picker("Split", selection: $split) {
                        ForEach(WorkoutSplit.allCases, id: \.self) { split in
                            Text(split.rawValue).tag(split)
                        }
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let routine = CustomRoutine(name: name, split: split)
                        routine.notes = notes.isEmpty ? nil : notes
                        modelContext.insert(routine)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [CustomRoutine.self], inMemory: true)
}

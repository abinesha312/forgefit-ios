import SwiftUI

struct ExerciseLibraryView: View {
    @StateObject private var library = ExerciseLibrary()
    @State private var searchText = ""
    @State private var selectedMuscleFilter: String?
    @State private var selectedEquipmentFilter: String?
    
    var filteredExercises: [Exercise] {
        var exercises = library.exercises
        
        if !searchText.isEmpty {
            exercises = library.search(query: searchText)
        }
        
        if let muscle = selectedMuscleFilter {
            exercises = exercises.filter { exercise in
                exercise.primaryMuscles.contains(muscle) || exercise.secondaryMuscles.contains(muscle)
            }
        }
        
        if let equipment = selectedEquipmentFilter {
            exercises = exercises.filter { exercise in
                exercise.equipment.contains(equipment)
            }
        }
        
        return exercises
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterSection
                
                List(filteredExercises) { exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        ExerciseRowView(exercise: exercise)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Exercise Library")
            .searchable(text: $searchText, prompt: "Search exercises")
        }
    }
    
    var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All Muscles",
                    isSelected: selectedMuscleFilter == nil,
                    action: { selectedMuscleFilter = nil }
                )
                
                ForEach(["Chest", "Back", "Shoulders", "Arms", "Legs", "Abs"], id: \.self) { muscle in
                    FilterChip(
                        title: muscle,
                        isSelected: selectedMuscleFilter == muscle,
                        action: { selectedMuscleFilter = selectedMuscleFilter == muscle ? nil : muscle }
                    )
                }
            }
            .padding()
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            
            Text(exercise.displayPrimaryMuscles)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(exercise.displayEquipment)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(exercise.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                if let imageUrl = exercise.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(16/9, contentMode: .fit)
                    }
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Category", systemImage: "tag")
                        .font(.headline)
                    Text(exercise.category)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Primary Muscles", systemImage: "figure.strengthtraining.traditional")
                        .font(.headline)
                    Text(exercise.displayPrimaryMuscles)
                        .foregroundStyle(.secondary)
                }
                
                if !exercise.secondaryMuscles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Secondary Muscles", systemImage: "figure.strengthtraining.traditional")
                            .font(.headline)
                        Text(exercise.displaySecondaryMuscles)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Equipment", systemImage: "dumbbell")
                        .font(.headline)
                    Text(exercise.displayEquipment)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Instructions", systemImage: "list.bullet")
                        .font(.headline)
                    Text(exercise.instructions)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ExerciseLibraryView()
}

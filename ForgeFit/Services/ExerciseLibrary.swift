import Foundation

@MainActor
class ExerciseLibrary: ObservableObject {
    @Published var exercises: [Exercise] = []
    
    init() {
        loadExercises()
    }
    
    func loadExercises() {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Exercise].self, from: data) else {
            print("Failed to load exercises from bundle")
            return
        }
        
        self.exercises = decoded
    }
    
    func search(query: String) -> [Exercise] {
        guard !query.isEmpty else { return exercises }
        
        return exercises.filter { exercise in
            exercise.name.lowercased().contains(query.lowercased()) ||
            exercise.primaryMuscles.contains { $0.lowercased().contains(query.lowercased()) } ||
            exercise.equipment.contains { $0.lowercased().contains(query.lowercased()) }
        }
    }
    
    func filterByMuscle(_ muscle: String) -> [Exercise] {
        exercises.filter { exercise in
            exercise.primaryMuscles.contains { $0.lowercased().contains(muscle.lowercased()) } ||
            exercise.secondaryMuscles.contains { $0.lowercased().contains(muscle.lowercased()) }
        }
    }
    
    func filterByEquipment(_ equipment: String) -> [Exercise] {
        exercises.filter { exercise in
            exercise.equipment.contains { $0.lowercased().contains(equipment.lowercased()) }
        }
    }
    
    func getExercise(id: String) -> Exercise? {
        exercises.first { $0.id == id }
    }
}

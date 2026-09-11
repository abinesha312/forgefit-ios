import Foundation
import SwiftData

@Model
class WorkoutSession {
    var id: UUID
    var date: Date
    var routineName: String
    var duration: TimeInterval
    var notes: String?
    var completed: Bool
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise]
    
    init(routineName: String, date: Date = Date()) {
        self.id = UUID()
        self.routineName = routineName
        self.date = date
        self.duration = 0
        self.completed = false
        self.exercises = []
    }
    
    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
}

@Model
class WorkoutExercise {
    var id: UUID
    var exerciseId: String
    var exerciseName: String
    var orderIndex: Int
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet]
    var notes: String?
    
    init(exerciseId: String, exerciseName: String, orderIndex: Int) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.orderIndex = orderIndex
        self.sets = []
    }
}

@Model
class ExerciseSet {
    var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var rpe: Double?
    var isWarmup: Bool
    var notes: String?
    var isPersonalRecord: Bool
    var completedAt: Date
    
    init(setNumber: Int, weight: Double = 0, reps: Int = 0, isWarmup: Bool = false) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isWarmup = isWarmup
        self.isPersonalRecord = false
        self.completedAt = Date()
    }
    
    var volume: Double {
        weight * Double(reps)
    }
}

@Model
class PersonalRecord {
    var id: UUID
    var exerciseId: String
    var exerciseName: String
    var weight: Double
    var reps: Int
    var achievedDate: Date
    var previousWeight: Double?
    var previousReps: Int?
    
    init(exerciseId: String, exerciseName: String, weight: Double, reps: Int, achievedDate: Date = Date()) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.achievedDate = achievedDate
    }
    
    var displayText: String {
        "\(Int(weight))kg x \(reps)"
    }
}

@Model
class WeightLog {
    var id: UUID
    var date: Date
    var weightKg: Double
    var notes: String?
    
    init(weightKg: Double, date: Date = Date(), notes: String? = nil) {
        self.id = UUID()
        self.weightKg = weightKg
        self.date = date
        self.notes = notes
    }
}

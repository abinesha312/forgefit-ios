import Foundation
import SwiftData

@Model
class CustomRoutine {
    var id: UUID
    var name: String
    var split: WorkoutSplit
    var notes: String?
    var isTemplate: Bool
    @Relationship(deleteRule: .cascade) var exercises: [RoutineExercise]
    var createdAt: Date
    
    init(name: String, split: WorkoutSplit, isTemplate: Bool = false) {
        self.id = UUID()
        self.name = name
        self.split = split
        self.isTemplate = isTemplate
        self.exercises = []
        self.createdAt = Date()
    }
}

@Model
class RoutineExercise {
    var id: UUID
    var exerciseId: String
    var exerciseName: String
    var orderIndex: Int
    var targetSets: Int
    var targetRepsMin: Int
    var targetRepsMax: Int
    var restSeconds: Int
    var notes: String?
    
    init(exerciseId: String, exerciseName: String, orderIndex: Int, targetSets: Int = 3, targetRepsMin: Int = 8, targetRepsMax: Int = 12, restSeconds: Int = 90) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.restSeconds = restSeconds
    }
    
    var targetRepsDisplay: String {
        if targetRepsMin == targetRepsMax {
            return "\(targetRepsMin)"
        }
        return "\(targetRepsMin)-\(targetRepsMax)"
    }
}

enum WorkoutSplit: String, Codable, CaseIterable {
    case fullBody = "Full Body"
    case upperLower = "Upper/Lower"
    case pushPullLegs = "Push/Pull/Legs"
    case bodyPart = "Body Part Split"
    case custom = "Custom"
}

struct WorkoutPlan {
    let weeklyRoutines: [DayRoutine]
    let split: WorkoutSplit
    let goal: BodyGoal
    
    struct DayRoutine {
        let dayOfWeek: Int
        let name: String
        let exercises: [PlannedExercise]
    }
    
    struct PlannedExercise {
        let exercise: Exercise
        let sets: Int
        let repsMin: Int
        let repsMax: Int
        let restSeconds: Int
    }
}

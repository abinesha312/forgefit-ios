import Foundation

@MainActor
class WorkoutPlanGenerator {
    
    static func generatePlan(for profile: UserProfile, exercises: [Exercise]) -> WorkoutPlan {
        let split = determineSplit(daysPerWeek: profile.trainingDaysPerWeek, goal: profile.bodyGoal)
        
        let filteredExercises = filterExercises(
            exercises,
            equipment: profile.equipment,
            experience: profile.experienceLevel
        )
        
        let routines = createRoutines(
            split: split,
            goal: profile.bodyGoal,
            experience: profile.experienceLevel,
            daysPerWeek: profile.trainingDaysPerWeek,
            exercises: filteredExercises
        )
        
        return WorkoutPlan(weeklyRoutines: routines, split: split, goal: profile.bodyGoal)
    }
    
    private static func determineSplit(daysPerWeek: Int, goal: BodyGoal) -> WorkoutSplit {
        switch daysPerWeek {
        case 2...3:
            return .fullBody
        case 4:
            return .upperLower
        case 5...6:
            return .pushPullLegs
        default:
            return .fullBody
        }
    }
    
    private static func filterExercises(_ exercises: [Exercise], equipment: Equipment, experience: ExperienceLevel) -> [Exercise] {
        let equipmentKeywords: [String]
        switch equipment {
        case .fullGym:
            equipmentKeywords = ["barbell", "dumbbell", "cable", "machine", "bodyweight"]
        case .dumbbells:
            equipmentKeywords = ["dumbbell", "bodyweight"]
        case .bodyweight:
            equipmentKeywords = ["bodyweight", "none"]
        case .homeLimited:
            equipmentKeywords = ["dumbbell", "bodyweight", "resistance band", "none"]
        }
        
        return exercises.filter { exercise in
            equipmentKeywords.contains { keyword in
                exercise.equipment.joined(separator: " ").lowercased().contains(keyword.lowercased())
            }
        }
    }
    
    private static func createRoutines(
        split: WorkoutSplit,
        goal: BodyGoal,
        experience: ExperienceLevel,
        daysPerWeek: Int,
        exercises: [Exercise]
    ) -> [WorkoutPlan.DayRoutine] {
        
        let (sets, repsMin, repsMax, rest) = getVolumeParameters(goal: goal, experience: experience)
        
        switch split {
        case .fullBody:
            return createFullBodySplit(daysPerWeek: daysPerWeek, exercises: exercises, sets: sets, repsMin: repsMin, repsMax: repsMax, rest: rest)
        case .upperLower:
            return createUpperLowerSplit(exercises: exercises, sets: sets, repsMin: repsMin, repsMax: repsMax, rest: rest)
        case .pushPullLegs:
            return createPushPullLegsSplit(daysPerWeek: daysPerWeek, exercises: exercises, sets: sets, repsMin: repsMin, repsMax: repsMax, rest: rest)
        default:
            return createFullBodySplit(daysPerWeek: daysPerWeek, exercises: exercises, sets: sets, repsMin: repsMin, repsMax: repsMax, rest: rest)
        }
    }
    
    private static func getVolumeParameters(goal: BodyGoal, experience: ExperienceLevel) -> (sets: Int, repsMin: Int, repsMax: Int, rest: Int) {
        switch goal {
        case .strength:
            return (5, 3, 5, 180)
        case .hypertrophy:
            return (4, 8, 12, 90)
        case .fatLoss:
            return (3, 12, 15, 60)
        case .generalFitness, .consistency:
            return (3, 8, 12, 90)
        }
    }
    
    private static func createFullBodySplit(daysPerWeek: Int, exercises: [Exercise], sets: Int, repsMin: Int, repsMax: Int, rest: Int) -> [WorkoutPlan.DayRoutine] {
        var routines: [WorkoutPlan.DayRoutine] = []
        
        let compounds = findExercisesByCategory(exercises, categories: ["Compound", "Strength"])
        let push = findExercisesByMuscle(exercises, muscles: ["Chest", "Shoulders", "Triceps"])
        let pull = findExercisesByMuscle(exercises, muscles: ["Back", "Biceps"])
        let legs = findExercisesByMuscle(exercises, muscles: ["Quadriceps", "Hamstrings", "Glutes"])
        let core = findExercisesByMuscle(exercises, muscles: ["Abs", "Obliques"])
        
        for day in 0..<daysPerWeek {
            var dayExercises: [WorkoutPlan.PlannedExercise] = []
            
            if let squat = compounds.first(where: { $0.name.lowercased().contains("squat") }) {
                dayExercises.append(WorkoutPlan.PlannedExercise(exercise: squat, sets: sets, repsMin: repsMin, repsMax: repsMax, restSeconds: rest))
            }
            
            if let bench = push.first(where: { $0.name.lowercased().contains("press") }) {
                dayExercises.append(WorkoutPlan.PlannedExercise(exercise: bench, sets: sets, repsMin: repsMin, repsMax: repsMax, restSeconds: rest))
            }
            
            if let row = pull.first(where: { $0.name.lowercased().contains("row") }) {
                dayExercises.append(WorkoutPlan.PlannedExercise(exercise: row, sets: sets, repsMin: repsMin, repsMax: repsMax, restSeconds: rest))
            }
            
            dayExercises.append(contentsOf: legs.prefix(2).map { WorkoutPlan.PlannedExercise(exercise: $0, sets: sets - 1, repsMin: repsMin, repsMax: repsMax, restSeconds: rest) })
            dayExercises.append(contentsOf: core.prefix(1).map { WorkoutPlan.PlannedExercise(exercise: $0, sets: 3, repsMin: 10, repsMax: 15, restSeconds: 60) })
            
            routines.append(WorkoutPlan.DayRoutine(dayOfWeek: day, name: "Full Body \(day + 1)", exercises: dayExercises))
        }
        
        return routines
    }
    
    private static func createUpperLowerSplit(exercises: [Exercise], sets: Int, repsMin: Int, repsMax: Int, rest: Int) -> [WorkoutPlan.DayRoutine] {
        let push = findExercisesByMuscle(exercises, muscles: ["Chest", "Shoulders", "Triceps"])
        let pull = findExercisesByMuscle(exercises, muscles: ["Back", "Biceps"])
        let legs = findExercisesByMuscle(exercises, muscles: ["Quadriceps", "Hamstrings", "Glutes"])
        let core = findExercisesByMuscle(exercises, muscles: ["Abs", "Obliques"])
        
        let upperExercises = (push.prefix(3) + pull.prefix(3)).map {
            WorkoutPlan.PlannedExercise(exercise: $0, sets: sets, repsMin: repsMin, repsMax: repsMax, restSeconds: rest)
        }
        
        let lowerExercises = legs.prefix(4).map {
            WorkoutPlan.PlannedExercise(exercise: $0, sets: sets, repsMin: repsMin, repsMax: repsMax, restSeconds: rest)
        } + core.prefix(2).map {
            WorkoutPlan.PlannedExercise(exercise: $0, sets: 3, repsMin: 10, repsMax: 15, restSeconds: 60)
        }
        
        return [
            WorkoutPlan.DayRoutine(dayOfWeek: 0, name: "Upper Body", exercises: upperExercises),
            WorkoutPlan.DayRoutine(dayOfWeek: 1, name: "Lower Body", exercises: lowerExercises),
            WorkoutPlan.DayRoutine(dayOfWeek: 3, name: "Upper Body", exercises: upperExercises),
            WorkoutPlan.DayRoutine(dayOfWeek: 4, name: "Lower Body", exercises: lowerExercises)
        ]
    }
    
    private static func createPushPullLegsSplit(daysPerWeek: Int, exercises: [Exercise], sets: Int, repsMin: Int, repsMax: Int, rest: Int) -> [WorkoutPlan.DayRoutine] {
        let push = findExercisesByMuscle(exercises, muscles: ["Chest", "Shoulders", "Triceps"])
        let pull = findExercisesByMuscle(exercises, muscles: ["Back", "Biceps"])
        let legs = findExercisesByMuscle(exercises, muscles: ["Quadriceps", "Hamstrings", "Glutes"])
        let core = findExercisesByMuscle(exercises, muscles: ["Abs", "Obliques"])
        
        let pushExercises = push.prefix(5).map {
            WorkoutPlan.PlannedExercise(exercise: $0, sets: sets, repsMin: repsMin, repsMax: repsMax, restSeconds: rest)
        }
        
        let pullExercises = pull.prefix(5).map {
            WorkoutPlan.PlannedExercise(exercise: $0, sets: sets, repsMin: repsMin, repsMax: repsMax, restSeconds: rest)
        }
        
        let legExercises = legs.prefix(4).map {
            WorkoutPlan.PlannedExercise(exercise: $0, sets: sets, repsMin: repsMin, repsMax: repsMax, restSeconds: rest)
        } + core.prefix(2).map {
            WorkoutPlan.PlannedExercise(exercise: $0, sets: 3, repsMin: 10, repsMax: 15, restSeconds: 60)
        }
        
        var routines = [
            WorkoutPlan.DayRoutine(dayOfWeek: 0, name: "Push", exercises: pushExercises),
            WorkoutPlan.DayRoutine(dayOfWeek: 1, name: "Pull", exercises: pullExercises),
            WorkoutPlan.DayRoutine(dayOfWeek: 2, name: "Legs", exercises: legExercises)
        ]
        
        if daysPerWeek >= 6 {
            routines.append(contentsOf: [
                WorkoutPlan.DayRoutine(dayOfWeek: 4, name: "Push", exercises: pushExercises),
                WorkoutPlan.DayRoutine(dayOfWeek: 5, name: "Pull", exercises: pullExercises),
                WorkoutPlan.DayRoutine(dayOfWeek: 6, name: "Legs", exercises: legExercises)
            ])
        }
        
        return routines
    }
    
    private static func findExercisesByMuscle(_ exercises: [Exercise], muscles: [String]) -> [Exercise] {
        exercises.filter { exercise in
            muscles.contains { muscle in
                exercise.primaryMuscles.contains { $0.lowercased().contains(muscle.lowercased()) }
            }
        }
    }
    
    private static func findExercisesByCategory(_ exercises: [Exercise], categories: [String]) -> [Exercise] {
        exercises.filter { exercise in
            categories.contains { exercise.category.lowercased().contains($0.lowercased()) }
        }
    }
}

import XCTest
import SwiftData
@testable import ForgeFit

@MainActor
final class ForgeFitTests: XCTestCase {
    
    var exerciseLibrary: [Exercise]!
    
    override func setUp() async throws {
        exerciseLibrary = [
            Exercise(
                id: "test_squat",
                name: "Barbell Squat",
                primaryMuscles: ["Quadriceps", "Glutes"],
                secondaryMuscles: ["Hamstrings"],
                equipment: ["Barbell"],
                category: "Compound",
                instructions: "Test instructions",
                imageUrl: nil
            ),
            Exercise(
                id: "test_bench",
                name: "Barbell Bench Press",
                primaryMuscles: ["Chest"],
                secondaryMuscles: ["Shoulders", "Triceps"],
                equipment: ["Barbell"],
                category: "Compound",
                instructions: "Test instructions",
                imageUrl: nil
            ),
            Exercise(
                id: "test_row",
                name: "Barbell Row",
                primaryMuscles: ["Back"],
                secondaryMuscles: ["Biceps"],
                equipment: ["Barbell"],
                category: "Compound",
                instructions: "Test instructions",
                imageUrl: nil
            ),
            Exercise(
                id: "test_ohp",
                name: "Overhead Press",
                primaryMuscles: ["Shoulders"],
                secondaryMuscles: ["Triceps"],
                equipment: ["Barbell"],
                category: "Compound",
                instructions: "Test instructions",
                imageUrl: nil
            ),
            Exercise(
                id: "test_deadlift",
                name: "Deadlift",
                primaryMuscles: ["Lower Back", "Glutes", "Hamstrings"],
                secondaryMuscles: ["Traps"],
                equipment: ["Barbell"],
                category: "Compound",
                instructions: "Test instructions",
                imageUrl: nil
            )
        ]
    }
    
    func testWorkoutPlanGeneratorFullBody() throws {
        let profile = UserProfile(
            name: "Test User",
            birthYear: 1990,
            heightCm: 175,
            weightKg: 75,
            bodyGoal: .strength,
            experienceLevel: .beginner,
            equipment: .fullGym,
            trainingDaysPerWeek: 3,
            sessionLengthMinutes: 60
        )
        
        let plan = WorkoutPlanGenerator.generatePlan(for: profile, exercises: exerciseLibrary)
        
        XCTAssertEqual(plan.split, .fullBody, "Should generate full body split for 3 days")
        XCTAssertEqual(plan.weeklyRoutines.count, 3, "Should have 3 routines for 3 training days")
        XCTAssertGreaterThan(plan.weeklyRoutines[0].exercises.count, 0, "Each routine should have exercises")
    }
    
    func testWorkoutPlanGeneratorUpperLower() throws {
        let profile = UserProfile(
            name: "Test User",
            birthYear: 1990,
            heightCm: 175,
            weightKg: 75,
            bodyGoal: .hypertrophy,
            experienceLevel: .intermediate,
            equipment: .fullGym,
            trainingDaysPerWeek: 4,
            sessionLengthMinutes: 60
        )
        
        let plan = WorkoutPlanGenerator.generatePlan(for: profile, exercises: exerciseLibrary)
        
        XCTAssertEqual(plan.split, .upperLower, "Should generate upper/lower split for 4 days")
        XCTAssertEqual(plan.weeklyRoutines.count, 4, "Should have 4 routines")
    }
    
    func testWorkoutPlanGeneratorPushPullLegs() throws {
        let profile = UserProfile(
            name: "Test User",
            birthYear: 1990,
            heightCm: 175,
            weightKg: 75,
            bodyGoal: .hypertrophy,
            experienceLevel: .advanced,
            equipment: .fullGym,
            trainingDaysPerWeek: 6,
            sessionLengthMinutes: 60
        )
        
        let plan = WorkoutPlanGenerator.generatePlan(for: profile, exercises: exerciseLibrary)
        
        XCTAssertEqual(plan.split, .pushPullLegs, "Should generate PPL split for 6 days")
        XCTAssertEqual(plan.weeklyRoutines.count, 6, "Should have 6 routines")
    }
    
    func testVolumeParametersStrength() throws {
        let profile = UserProfile(
            name: "Test User",
            birthYear: 1990,
            heightCm: 175,
            weightKg: 75,
            bodyGoal: .strength,
            experienceLevel: .intermediate,
            equipment: .fullGym,
            trainingDaysPerWeek: 3,
            sessionLengthMinutes: 60
        )
        
        let plan = WorkoutPlanGenerator.generatePlan(for: profile, exercises: exerciseLibrary)
        
        let firstExercise = plan.weeklyRoutines[0].exercises[0]
        XCTAssertGreaterThanOrEqual(firstExercise.sets, 3, "Strength should have at least 3 sets")
        XCTAssertLessThanOrEqual(firstExercise.repsMax, 5, "Strength should have lower reps")
    }
    
    func testVolumeParametersHypertrophy() throws {
        let profile = UserProfile(
            name: "Test User",
            birthYear: 1990,
            heightCm: 175,
            weightKg: 75,
            bodyGoal: .hypertrophy,
            experienceLevel: .intermediate,
            equipment: .fullGym,
            trainingDaysPerWeek: 4,
            sessionLengthMinutes: 60
        )
        
        let plan = WorkoutPlanGenerator.generatePlan(for: profile, exercises: exerciseLibrary)
        
        let firstExercise = plan.weeklyRoutines[0].exercises[0]
        XCTAssertGreaterThanOrEqual(firstExercise.repsMin, 6, "Hypertrophy should have moderate to high reps")
        XCTAssertLessThanOrEqual(firstExercise.repsMax, 15, "Hypertrophy should have moderate to high reps")
    }
    
    func testPersonalRecordDetection() throws {
        let pr1 = PersonalRecord(
            exerciseId: "test_bench",
            exerciseName: "Bench Press",
            weight: 100,
            reps: 5,
            achievedDate: Date()
        )
        
        XCTAssertEqual(pr1.displayText, "100kg x 5")
        
        pr1.previousWeight = 95
        pr1.previousReps = 5
        
        XCTAssertNotNil(pr1.previousWeight)
        XCTAssertNotNil(pr1.previousReps)
    }
    
    func testExerciseSetVolumeCalculation() throws {
        let set = ExerciseSet(setNumber: 1, weight: 100, reps: 10)
        
        XCTAssertEqual(set.volume, 1000, "Volume should be weight × reps")
    }
    
    func testWorkoutSessionTotalVolume() throws {
        let session = WorkoutSession(routineName: "Test Workout")
        
        let exercise1 = WorkoutExercise(exerciseId: "test1", exerciseName: "Exercise 1", orderIndex: 0)
        let set1 = ExerciseSet(setNumber: 1, weight: 100, reps: 10)
        let set2 = ExerciseSet(setNumber: 2, weight: 100, reps: 10)
        exercise1.sets.append(set1)
        exercise1.sets.append(set2)
        
        let exercise2 = WorkoutExercise(exerciseId: "test2", exerciseName: "Exercise 2", orderIndex: 1)
        let set3 = ExerciseSet(setNumber: 1, weight: 50, reps: 12)
        exercise2.sets.append(set3)
        
        session.exercises.append(exercise1)
        session.exercises.append(exercise2)
        
        XCTAssertEqual(session.totalVolume, 2600, "Total volume should be sum of all set volumes")
        XCTAssertEqual(session.totalSets, 3, "Total sets should be 3")
    }
    
    func testExerciseLibrarySearch() throws {
        let library = ExerciseLibrary()
        library.exercises = exerciseLibrary
        
        let results = library.search(query: "squat")
        XCTAssertEqual(results.count, 1, "Should find 1 exercise matching 'squat'")
        XCTAssertEqual(results[0].name, "Barbell Squat")
        
        let emptyResults = library.search(query: "nonexistent")
        XCTAssertEqual(emptyResults.count, 0, "Should find no exercises")
        
        let allResults = library.search(query: "")
        XCTAssertEqual(allResults.count, exerciseLibrary.count, "Empty query should return all exercises")
    }
    
    func testExerciseLibraryFilterByMuscle() throws {
        let library = ExerciseLibrary()
        library.exercises = exerciseLibrary
        
        let chestExercises = library.filterByMuscle("Chest")
        XCTAssertGreaterThan(chestExercises.count, 0, "Should find chest exercises")
        XCTAssertTrue(chestExercises.allSatisfy { exercise in
            exercise.primaryMuscles.contains { $0.lowercased().contains("chest") } ||
            exercise.secondaryMuscles.contains { $0.lowercased().contains("chest") }
        })
    }
    
    func testExerciseLibraryFilterByEquipment() throws {
        let library = ExerciseLibrary()
        library.exercises = exerciseLibrary
        
        let barbellExercises = library.filterByEquipment("Barbell")
        XCTAssertEqual(barbellExercises.count, exerciseLibrary.count, "All test exercises use barbell")
        XCTAssertTrue(barbellExercises.allSatisfy { exercise in
            exercise.equipment.contains { $0.lowercased().contains("barbell") }
        })
    }
    
    func testUserProfileCreation() throws {
        let profile = UserProfile(
            name: "Test User",
            sex: "Male",
            birthYear: 1995,
            heightCm: 180,
            weightKg: 80,
            bodyGoal: .strength,
            experienceLevel: .intermediate,
            equipment: .fullGym,
            trainingDaysPerWeek: 4,
            sessionLengthMinutes: 75
        )
        
        XCTAssertEqual(profile.name, "Test User")
        XCTAssertEqual(profile.sex, "Male")
        XCTAssertEqual(profile.birthYear, 1995)
        XCTAssertEqual(profile.heightCm, 180)
        XCTAssertEqual(profile.weightKg, 80)
        XCTAssertEqual(profile.bodyGoal, .strength)
        XCTAssertEqual(profile.experienceLevel, .intermediate)
        XCTAssertEqual(profile.equipment, .fullGym)
        XCTAssertEqual(profile.trainingDaysPerWeek, 4)
        XCTAssertEqual(profile.sessionLengthMinutes, 75)
        XCTAssertEqual(profile.currentStreak, 0)
        XCTAssertNil(profile.lastWorkoutDate)
    }
    
    func testWeightLogCreation() throws {
        let log = WeightLog(weightKg: 75.5, date: Date(), notes: "Morning weight")
        
        XCTAssertEqual(log.weightKg, 75.5)
        XCTAssertEqual(log.notes, "Morning weight")
        XCTAssertNotNil(log.date)
    }
}

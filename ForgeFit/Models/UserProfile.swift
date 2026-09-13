import Foundation
import SwiftData

@Model
class UserProfile {
    var id: UUID
    var name: String
    var sex: String?
    var birthYear: Int
    var heightCm: Double
    var weightKg: Double
    var bodyGoal: BodyGoal
    var experienceLevel: ExperienceLevel
    var equipment: Equipment
    var trainingDaysPerWeek: Int
    var sessionLengthMinutes: Int
    var createdAt: Date
    var currentStreak: Int
    var lastWorkoutDate: Date?
    
    init(
        name: String,
        sex: String? = nil,
        birthYear: Int,
        heightCm: Double,
        weightKg: Double,
        bodyGoal: BodyGoal,
        experienceLevel: ExperienceLevel,
        equipment: Equipment,
        trainingDaysPerWeek: Int,
        sessionLengthMinutes: Int
    ) {
        self.id = UUID()
        self.name = name
        self.sex = sex
        self.birthYear = birthYear
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.bodyGoal = bodyGoal
        self.experienceLevel = experienceLevel
        self.equipment = equipment
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.sessionLengthMinutes = sessionLengthMinutes
        self.createdAt = Date()
        self.currentStreak = 0
        self.lastWorkoutDate = nil
    }
}

enum BodyGoal: String, Codable, CaseIterable {
    case strength = "Strength"
    case hypertrophy = "Hypertrophy / Muscle Gain"
    case fatLoss = "Fat Loss"
    case generalFitness = "General Fitness"
    case consistency = "Consistency"
}

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum Equipment: String, Codable, CaseIterable {
    case fullGym = "Full Gym"
    case dumbbells = "Dumbbells"
    case bodyweight = "Bodyweight"
    case homeLimited = "Home (Limited Equipment)"
}

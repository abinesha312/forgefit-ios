import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: [String]
    let category: String
    let instructions: String
    let imageUrl: String?
    
    var displayEquipment: String {
        equipment.joined(separator: ", ")
    }
    
    var displayPrimaryMuscles: String {
        primaryMuscles.joined(separator: ", ")
    }
    
    var displaySecondaryMuscles: String {
        secondaryMuscles.joined(separator: ", ")
    }
}

enum MuscleGroup: String, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case abs = "Abs"
    case obliques = "Obliques"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case lowerBack = "Lower Back"
    case traps = "Traps"
    
    var emoji: String {
        switch self {
        case .chest: return "💪"
        case .back: return "🔙"
        case .shoulders: return "🏋️"
        case .biceps: return "💪"
        case .triceps: return "💪"
        case .forearms: return "✊"
        case .abs: return "🎯"
        case .obliques: return "〰️"
        case .quadriceps: return "🦵"
        case .hamstrings: return "🦵"
        case .glutes: return "🍑"
        case .calves: return "🦶"
        case .lowerBack: return "🔙"
        case .traps: return "🏔️"
        }
    }
}

import SwiftUI
import SwiftData

@main
struct ForgeFitApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(for: [
                    UserProfile.self,
                    WorkoutSession.self,
                    WorkoutExercise.self,
                    ExerciseSet.self,
                    WeightLog.self,
                    PersonalRecord.self,
                    CustomRoutine.self,
                    RoutineExercise.self
                ])
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var currentWorkoutSession: WorkoutSession?
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

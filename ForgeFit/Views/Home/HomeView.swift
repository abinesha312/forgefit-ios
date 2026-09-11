import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    @Query private var profiles: [UserProfile]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var recentWorkouts: [WorkoutSession]
    @Query private var personalRecords: [PersonalRecord]
    
    @StateObject private var exerciseLibrary = ExerciseLibrary()
    @State private var todaysPlan: WorkoutPlan?
    @State private var showingPlanGenerator = false
    
    var profile: UserProfile? {
        profiles.first
    }
    
    var streak: Int {
        profile?.currentStreak ?? 0
    }
    
    var todaysDayOfWeek: Int {
        Calendar.current.component(.weekday, from: Date()) - 1
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    greetingSection
                    
                    if appState.currentWorkoutSession != nil {
                        activeWorkoutBanner
                    }
                    
                    streakCard
                    
                    if let routine = todaysPlan?.weeklyRoutines.first(where: { $0.dayOfWeek == todaysDayOfWeek }) {
                        todaysWorkoutCard(routine: routine)
                    } else {
                        generatePlanCard
                    }
                    
                    recentWorkoutsSection
                }
                .padding()
            }
            .navigationTitle("Home")
            .task {
                if let profile = profile, todaysPlan == nil {
                    todaysPlan = WorkoutPlanGenerator.generatePlan(for: profile, exercises: exerciseLibrary.exercises)
                }
            }
        }
    }
    
    var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.title)
                .fontWeight(.bold)
            
            if let profile = profile {
                Text(profile.name)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    var activeWorkoutBanner: some View {
        NavigationLink(destination: ActiveWorkoutView()) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                Text("Resume Active Workout")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(streak) days")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    func todaysWorkoutCard(routine: WorkoutPlan.DayRoutine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Workout")
                .font(.headline)
            
            Text(routine.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("\(routine.exercises.count) exercises")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            NavigationLink(destination: StartWorkoutView(routine: routine)) {
                HStack {
                    Spacer()
                    Text("Start Workout")
                        .fontWeight(.semibold)
                    Image(systemName: "play.fill")
                    Spacer()
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    var generatePlanCard: some View {
        VStack(spacing: 12) {
            Text("No workout planned for today")
                .font(.headline)
            
            Button(action: {
                if let profile = profile {
                    todaysPlan = WorkoutPlanGenerator.generatePlan(for: profile, exercises: exerciseLibrary.exercises)
                }
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Plan")
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
            
            if recentWorkouts.isEmpty {
                Text("No workouts yet. Start your first workout!")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(recentWorkouts.prefix(5)) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutRowView(workout: workout)
                    }
                }
            }
        }
    }
}

struct WorkoutRowView: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.routineName)
                    .font(.headline)
                
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.exercises.count) exercises")
                    .font(.caption)
                
                Text("\(Int(workout.duration / 60))m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct WorkoutDetailView: View {
    let workout: WorkoutSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(workout.routineName)
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                    Spacer()
                    Label("\(Int(workout.duration / 60)) minutes", systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                Divider()
                
                ForEach(workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.exerciseName)
                            .font(.headline)
                        
                        ForEach(exercise.sets) { set in
                            HStack {
                                Text("Set \(set.setNumber)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(set.weight))kg × \(set.reps)")
                                    .fontWeight(.semibold)
                                if set.isPersonalRecord {
                                    Text("PR")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .modelContainer(for: [UserProfile.self, WorkoutSession.self], inMemory: true)
}

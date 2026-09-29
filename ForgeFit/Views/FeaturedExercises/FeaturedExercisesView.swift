import SwiftUI

struct FeaturedExercisesView: View {
    @StateObject private var backend = BackendClient.shared
    @State private var exercises: [BackendExercise] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let muscleIcons: [String: String] = [
        "chest": "💪",
        "shoulders": "🏋️",
        "back": "🔙",
        "quads": "🦵",
        "hamstrings": "🦵",
        "glutes": "🍑",
        "core": "🎯",
        "calves": "🦶",
        "rear delts": "🏔️"
    ]
    
    private let muscleColors: [String: Color] = [
        "chest": .red,
        "shoulders": .orange,
        "back": .blue,
        "quads": .purple,
        "hamstrings": .pink,
        "glutes": .yellow,
        "core": .green,
        "calves": .cyan,
        "rear delts": .indigo
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading...")
                        .tint(.lime)
                        .foregroundColor(.white)
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.lime)
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.white)
                        Text(error)
                            .foregroundColor(.gray)
                        Button("Retry") {
                            Task { await loadExercises() }
                        }
                        .buttonStyle(LimeButtonStyle())
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            headerSection
                            
                            ForEach(exercises) { exercise in
                                ExerciseCard(
                                    exercise: exercise,
                                    icon: muscleIcons[exercise.muscle] ?? "💪",
                                    color: muscleColors[exercise.muscle] ?? .gray
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Featured Exercises")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .task {
                await loadExercises()
            }
        }
    }
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("10 Core Movements")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.lime)
            
            Text("Build total-body strength with these essential exercises targeting all major muscle groups.")
                .font(.body)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    func loadExercises() async {
        isLoading = true
        errorMessage = nil
        
        do {
            exercises = try await backend.getExercises()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct ExerciseCard: View {
    let exercise: BackendExercise
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(icon)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text(exercise.muscle.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.3))
                            .foregroundColor(color)
                            .cornerRadius(6)
                        
                        Text(exercise.category.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            Text(exercise.description)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct LimeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.lime)
            .foregroundColor(.black)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

extension Color {
    static let lime = Color(red: 0.75, green: 1.0, blue: 0.0)
}

#Preview {
    FeaturedExercisesView()
}

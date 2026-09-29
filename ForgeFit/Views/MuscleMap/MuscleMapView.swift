import SwiftUI
import Charts

struct MuscleMapView: View {
    @StateObject private var backend = BackendClient.shared
    @State private var muscleMap: MuscleMapResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
                            Task { await loadMuscleMap() }
                        }
                        .buttonStyle(LimeButtonStyle())
                    }
                    .padding()
                } else if let muscleMap = muscleMap {
                    ScrollView {
                        VStack(spacing: 24) {
                            headerSection
                            
                            if !muscleMap.muscles.isEmpty {
                                volumeChart(muscles: muscleMap.muscles)
                                
                                muscleList(muscles: muscleMap.muscles)
                            } else {
                                emptyState
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Muscle Map")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .task {
                await loadMuscleMap()
            }
        }
    }
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Volume by Muscle")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.lime)
            
            Text("Track which muscle groups you've been targeting")
                .font(.body)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    func volumeChart(muscles: [MuscleVolume]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Volume Distribution")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart(muscles) { muscle in
                BarMark(
                    x: .value("Volume", muscle.volume),
                    y: .value("Muscle", muscle.muscle.capitalized)
                )
                .foregroundStyle(Color.lime.gradient)
            }
            .frame(height: max(CGFloat(muscles.count * 40), 200))
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(Color.gray)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    func muscleList(muscles: [MuscleVolume]) -> some View {
        VStack(spacing: 12) {
            ForEach(muscles.sorted(by: { $0.volume > $1.volume })) { muscle in
                MuscleRow(muscle: muscle)
            }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No workout data yet")
                .font(.title2)
                .foregroundColor(.white)
            Text("Start logging workouts to see your muscle volume distribution")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    func loadMuscleMap() async {
        isLoading = true
        errorMessage = nil
        
        do {
            muscleMap = try await backend.getMuscleMap()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct MuscleRow: View {
    let muscle: MuscleVolume
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(muscle.muscle.capitalized)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(muscle.exerciseCount) exercise\(muscle.exerciseCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(muscle.volume)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.lime)
                
                Text("volume")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

#Preview {
    MuscleMapView()
}

import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workouts: [WorkoutSession]
    @Query(sort: \WeightLog.date, order: .reverse) private var weightLogs: [WeightLog]
    @Query(sort: \PersonalRecord.achievedDate, order: .reverse) private var personalRecords: [PersonalRecord]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsCards
                    
                    weeklyVolumeChart
                    
                    bodyWeightChart
                    
                    personalRecordsSection
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
    
    var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(title: "Workouts", value: "\(workouts.count)", icon: "figure.strengthtraining.traditional")
            StatCard(title: "Total Volume", value: "\(Int(totalVolume))kg", icon: "scalemass")
            StatCard(title: "PRs", value: "\(personalRecords.count)", icon: "trophy")
        }
    }
    
    var totalVolume: Double {
        workouts.reduce(0) { $0 + $1.totalVolume }
    }
    
    var weeklyVolumeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Volume")
                .font(.headline)
            
            if weeklyVolumeData.isEmpty {
                Text("No workout data yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Chart(weeklyVolumeData) { data in
                    BarMark(
                        x: .value("Week", data.week),
                        y: .value("Volume", data.volume)
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    var weeklyVolumeData: [(week: String, volume: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: workouts) { workout in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.date)
        }
        
        return grouped.map { key, workouts in
            let weekStr = "W\(key.weekOfYear ?? 0)"
            let volume = workouts.reduce(0) { $0 + $1.totalVolume }
            return (weekStr, volume)
        }.sorted { $0.week < $1.week }
    }
    
    var bodyWeightChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Weight")
                .font(.headline)
            
            if weightLogs.isEmpty {
                Text("No weight logs yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Chart(weightLogs.prefix(30).reversed()) { log in
                    LineMark(
                        x: .value("Date", log.date),
                        y: .value("Weight", log.weightKg)
                    )
                    .foregroundStyle(Color.blue)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)
            
            if personalRecords.isEmpty {
                Text("No PRs yet. Keep lifting!")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(personalRecords.prefix(10)) { pr in
                    PersonalRecordRow(pr: pr)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct PersonalRecordRow: View {
    let pr: PersonalRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exerciseName)
                    .font(.headline)
                
                Text(pr.achievedDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(pr.displayText)
                    .font(.headline)
                    .foregroundColor(.green)
                
                if let prevWeight = pr.previousWeight, let prevReps = pr.previousReps {
                    Text("\(Int(prevWeight))kg × \(prevReps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    ProgressView()
        .modelContainer(for: [WorkoutSession.self, WeightLog.self, PersonalRecord.self], inMemory: true)
}

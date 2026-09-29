import SwiftUI
import ReplayKit

struct CoachModeView: View {
    @StateObject private var backend = BackendClient.shared
    @StateObject private var screenRecorder = ScreenRecorder()
    @State private var sessionId: String?
    @State private var sessionTitle = ""
    @State private var showingSessionInput = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        statusCard
                        
                        if screenRecorder.isRecording {
                            activeSessionSection
                        } else {
                            startSessionSection
                        }
                        
                        if let error = errorMessage {
                            ErrorBanner(message: error)
                        }
                        
                        featuresList
                        
                        disclaimer
                    }
                    .padding()
                }
            }
            .navigationTitle("Coach Mode")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showingSessionInput) {
                SessionInputSheet(
                    sessionTitle: $sessionTitle,
                    onStart: startSession
                )
            }
        }
    }
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "video.fill")
                    .font(.title)
                    .foregroundColor(.lime)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screen Sharing")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Share your workouts with your coach")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.lime.opacity(0.1), Color.lime.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    var statusCard: some View {
        HStack {
            Circle()
                .fill(screenRecorder.isRecording ? Color.red : Color.gray)
                .frame(width: 12, height: 12)
            
            Text(screenRecorder.isRecording ? "Recording Active" : "Not Recording")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            if screenRecorder.isRecording {
                Text(formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.lime)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
    
    var startSessionSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.lime)
            
            Text("Ready to Share")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Start a screen recording session to share your workout with your coach")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button {
                showingSessionInput = true
            } label: {
                HStack {
                    Image(systemName: "record.circle")
                    Text("Start Screen Share")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.lime)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    var activeSessionSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "record.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            if !sessionTitle.isEmpty {
                Text(sessionTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text("Recording in Progress")
                .font(.headline)
                .foregroundColor(.gray)
            
            Button {
                stopSession()
            } label: {
                HStack {
                    Image(systemName: "stop.circle")
                    Text("Stop Recording")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
    }
    
    var featuresList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Features")
                .font(.headline)
                .foregroundColor(.white)
            
            FeatureRow(icon: "video", title: "In-App Recording", description: "Uses ReplayKit for screen capture")
            FeatureRow(icon: "lock.shield", title: "Local Storage", description: "Recordings stored on your device")
            FeatureRow(icon: "clock", title: "Session Tracking", description: "Metadata synced to backend")
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    var disclaimer: some View {
        VStack(spacing: 8) {
            Text("ℹ️ Beta Feature")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("Screen recording uses iOS ReplayKit. Video storage and remote streaming require additional implementation. Currently captures session metadata only.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    var formattedDuration: String {
        let duration = Int(screenRecorder.recordingDuration)
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startSession() {
        Task {
            do {
                let session = try await backend.createShareSession(title: sessionTitle)
                sessionId = session.id
                errorMessage = nil
                
                await screenRecorder.startRecording()
            } catch {
                errorMessage = "Failed to start session: \(error.localizedDescription)"
            }
        }
    }
    
    func stopSession() {
        Task {
            await screenRecorder.stopRecording()
            
            if let id = sessionId {
                do {
                    _ = try await backend.stopShareSession(id: id)
                    errorMessage = nil
                } catch {
                    errorMessage = "Failed to stop session on backend: \(error.localizedDescription)"
                }
            }
            
            sessionId = nil
            sessionTitle = ""
        }
    }
}

struct SessionInputSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var sessionTitle: String
    let onStart: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Name Your Session")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    TextField("e.g., Morning Chest Workout", text: $sessionTitle)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    
                    Button {
                        onStart()
                        dismiss()
                    } label: {
                        Text("Start Recording")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lime)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .disabled(sessionTitle.isEmpty)
                    .opacity(sessionTitle.isEmpty ? 0.5 : 1.0)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.lime)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.lime)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.red.opacity(0.2))
        .cornerRadius(10)
    }
}

@MainActor
class ScreenRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    
    private var recorder = RPScreenRecorder.shared()
    private var timer: Timer?
    private var startTime: Date?
    
    func startRecording() async {
        guard recorder.isAvailable else {
            print("Screen recording not available")
            return
        }
        
        do {
            try await recorder.startRecording()
            isRecording = true
            startTime = Date()
            startTimer()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() async {
        guard recorder.isRecording else { return }
        
        do {
            try await recorder.stopRecording()
            isRecording = false
            stopTimer()
            recordingDuration = 0
        } catch {
            print("Failed to stop recording: \(error.localizedDescription)")
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.recordingDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        startTime = nil
    }
}

#Preview {
    CoachModeView()
}

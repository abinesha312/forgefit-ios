import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingFlowView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

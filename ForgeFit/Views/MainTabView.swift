import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            FeaturedExercisesView()
                .tabItem {
                    Label("Featured", systemImage: "star.fill")
                }
                .tag(1)
            
            MuscleMapView()
                .tabItem {
                    Label("Muscles", systemImage: "figure.arms.open")
                }
                .tag(2)
            
            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(3)
            
            CoachModeView()
                .tabItem {
                    Label("Coach", systemImage: "video.fill")
                }
                .tag(4)
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(5)
        }
        .accentColor(.lime)
    }
}

extension Color {
    static let lime = Color(red: 0.75, green: 1.0, blue: 0.0)
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}

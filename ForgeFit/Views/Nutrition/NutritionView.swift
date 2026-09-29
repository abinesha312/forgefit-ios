import SwiftUI
import Charts

struct NutritionView: View {
    @StateObject private var backend = BackendClient.shared
    @State private var dietPlan: DietPlanWithMeals?
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
                            Task { await loadDietPlan() }
                        }
                        .buttonStyle(LimeButtonStyle())
                    }
                    .padding()
                } else if let plan = dietPlan {
                    ScrollView {
                        VStack(spacing: 24) {
                            macroSummary(plan: plan.plan)
                            
                            macroBreakdown(plan: plan.plan)
                            
                            mealsSection(meals: plan.meals)
                            
                            disclaimer
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .task {
                await loadDietPlan()
            }
        }
    }
    
    func macroSummary(plan: DietPlan) -> some View {
        VStack(spacing: 16) {
            Text("Today's Targets")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.lime)
            
            HStack(spacing: 20) {
                MacroCard(title: "Calories", value: "\(plan.totalCalories)", unit: "kcal", color: .lime)
                MacroCard(title: "Protein", value: "\(plan.proteinG)", unit: "g", color: .blue)
                MacroCard(title: "Carbs", value: "\(plan.carbsG)", unit: "g", color: .orange)
                MacroCard(title: "Fat", value: "\(plan.fatG)", unit: "g", color: .purple)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.lime.opacity(0.1), Color.lime.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    func macroBreakdown(plan: DietPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macro Split")
                .font(.headline)
                .foregroundColor(.white)
            
            let totalGrams = Double(plan.proteinG + plan.carbsG + plan.fatG)
            let proteinPercent = Double(plan.proteinG) / totalGrams * 100
            let carbsPercent = Double(plan.carbsG) / totalGrams * 100
            let fatPercent = Double(plan.fatG) / totalGrams * 100
            
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat(proteinPercent) * 3)
                
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: CGFloat(carbsPercent) * 3)
                
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: CGFloat(fatPercent) * 3)
            }
            .frame(height: 24)
            .cornerRadius(12)
            
            HStack(spacing: 20) {
                LegendItem(color: .blue, label: "Protein \(Int(proteinPercent))%")
                LegendItem(color: .orange, label: "Carbs \(Int(carbsPercent))%")
                LegendItem(color: .purple, label: "Fat \(Int(fatPercent))%")
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    func mealsSection(meals: [Meal]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ForEach(meals) { meal in
                MealCard(meal: meal)
            }
        }
    }
    
    var disclaimer: some View {
        VStack(spacing: 8) {
            Text("⚠️ Informational Only")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
            
            Text("This nutrition plan is for tracking purposes only. Consult with a healthcare provider or registered dietitian before making dietary changes.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    func loadDietPlan() async {
        isLoading = true
        errorMessage = nil
        
        do {
            dietPlan = try await backend.getDietToday()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct MacroCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct MealCard: View {
    let meal: Meal
    
    private var mealIcon: String {
        switch meal.mealType.lowercased() {
        case "breakfast": return "🌅"
        case "lunch": return "☀️"
        case "dinner": return "🌙"
        case "snack": return "🍎"
        default: return "🍽️"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(mealIcon)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.mealType.capitalized)
                        .font(.caption)
                        .foregroundColor(.lime)
                        .fontWeight(.semibold)
                    
                    Text(meal.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("\(meal.calories) kcal")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.lime)
            }
            
            Text(meal.description)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                MacroLabel(label: "P", value: meal.proteinG, color: .blue)
                MacroLabel(label: "C", value: meal.carbsG, color: .orange)
                MacroLabel(label: "F", value: meal.fatG, color: .purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.lime.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct MacroLabel: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text("\(value)g")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    NutritionView()
}

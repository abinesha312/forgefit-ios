import Foundation

@MainActor
class BackendClient: ObservableObject {
    static let shared = BackendClient()
    
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String = "http://127.0.0.1:8080") {
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    private func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BackendError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw BackendError.decodingError(error)
        }
    }
    
    func checkHealth() async throws -> HealthResponse {
        try await request("/health")
    }
    
    func getExercises() async throws -> [BackendExercise] {
        try await request("/api/v1/exercises")
    }
    
    func getMuscleMap() async throws -> MuscleMapResponse {
        try await request("/api/v1/muscle-map")
    }
    
    func getDietToday() async throws -> DietPlanWithMeals {
        try await request("/api/v1/diet/today")
    }
    
    func getDietPlans() async throws -> [DietPlan] {
        try await request("/api/v1/diet/plans")
    }
    
    func createWorkout(_ workout: CreateWorkoutRequest) async throws -> WorkoutResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(workout)
        return try await request("/api/v1/workouts", method: "POST", body: body)
    }
    
    func getWorkouts() async throws -> [WorkoutResponse] {
        try await request("/api/v1/workouts")
    }
    
    func createShareSession(title: String) async throws -> ShareSessionResponse {
        let body = try JSONEncoder().encode(["title": title])
        return try await request("/api/v1/share-sessions", method: "POST", body: body)
    }
    
    func stopShareSession(id: String) async throws -> ShareSessionResponse {
        try await request("/api/v1/share-sessions/\(id)/stop", method: "POST")
    }
    
    func getShareSession(id: String) async throws -> ShareSessionResponse {
        try await request("/api/v1/share-sessions/\(id)")
    }
}

enum BackendError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

struct HealthResponse: Codable {
    let status: String
    let service: String
    let version: String
}

struct BackendExercise: Codable, Identifiable {
    let id: String
    let name: String
    let muscle: String
    let category: String
    let description: String
}

struct MuscleMapResponse: Codable {
    let muscles: [MuscleVolume]
}

struct MuscleVolume: Codable, Identifiable {
    var id: String { muscle }
    let muscle: String
    let volume: Int
    let exerciseCount: Int
}

struct DietPlanWithMeals: Codable {
    let plan: DietPlan
    let meals: [Meal]
    
    enum CodingKeys: String, CodingKey {
        case id, date
        case totalCalories = "total_calories"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case meals
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let date = try container.decode(String.self, forKey: .date)
        let totalCalories = try container.decode(Int.self, forKey: .totalCalories)
        let proteinG = try container.decode(Int.self, forKey: .proteinG)
        let carbsG = try container.decode(Int.self, forKey: .carbsG)
        let fatG = try container.decode(Int.self, forKey: .fatG)
        
        self.plan = DietPlan(
            id: id,
            date: date,
            totalCalories: totalCalories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG
        )
        self.meals = try container.decode([Meal].self, forKey: .meals)
    }
}

struct DietPlan: Codable, Identifiable {
    let id: String
    let date: String
    let totalCalories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
}

struct Meal: Codable, Identifiable {
    let id: String
    let dietPlanId: String
    let mealType: String
    let name: String
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let description: String
}

struct CreateWorkoutRequest: Codable {
    let exerciseName: String
    let sets: Int
    let reps: Int
    let weightKg: Double
    let notes: String?
}

struct WorkoutResponse: Codable, Identifiable {
    let id: String
    let exerciseName: String
    let sets: Int
    let reps: Int
    let weightKg: Double
    let notes: String?
    let createdAt: String
}

struct ShareSessionResponse: Codable, Identifiable {
    let id: String
    let title: String
    let status: String
    let startedAt: String
    let stoppedAt: String?
}

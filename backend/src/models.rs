use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Exercise {
    pub id: String,
    pub name: String,
    pub muscle: String,
    pub category: String,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MuscleMap {
    pub muscles: Vec<MuscleVolume>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MuscleVolume {
    pub muscle: String,
    pub volume: u32,
    pub exercise_count: u32,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct DietPlan {
    pub id: String,
    pub date: String,
    pub total_calories: i32,
    pub protein_g: i32,
    pub carbs_g: i32,
    pub fat_g: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DietPlanWithMeals {
    #[serde(flatten)]
    pub plan: DietPlan,
    pub meals: Vec<Meal>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Meal {
    pub id: String,
    pub diet_plan_id: String,
    pub meal_type: String,
    pub name: String,
    pub calories: i32,
    pub protein_g: i32,
    pub carbs_g: i32,
    pub fat_g: i32,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Workout {
    pub id: String,
    pub exercise_name: String,
    pub sets: i32,
    pub reps: i32,
    pub weight_kg: f64,
    pub notes: Option<String>,
    pub created_at: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateWorkoutRequest {
    pub exercise_name: String,
    pub sets: i32,
    pub reps: i32,
    pub weight_kg: f64,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct ShareSession {
    pub id: String,
    pub title: String,
    pub status: String,
    pub started_at: String,
    pub stopped_at: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateShareSessionRequest {
    pub title: String,
}

use axum::{
    extract::{Path, State},
    http::{Method, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use sqlx::{sqlite::SqlitePool, Row};
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod models;
mod seed;
#[cfg(test)]
mod tests;

use models::*;
use seed::seed_database;

#[derive(Clone)]
struct AppState {
    db: SqlitePool,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:forgefit.db".to_string());

    let pool = SqlitePool::connect(&database_url).await?;
    
    sqlx::migrate!("./migrations").run(&pool).await?;
    
    seed_database(&pool).await?;

    let state = AppState { db: pool };

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
        .allow_headers(Any);

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/api/v1/exercises", get(get_exercises))
        .route("/api/v1/muscle-map", get(get_muscle_map))
        .route("/api/v1/diet/today", get(get_diet_today))
        .route("/api/v1/diet/plans", get(get_diet_plans))
        .route("/api/v1/workouts", post(create_workout))
        .route("/api/v1/workouts", get(get_workouts))
        .route("/api/v1/workouts/:id", get(get_workout_by_id))
        .route("/api/v1/share-sessions", post(create_share_session))
        .route("/api/v1/share-sessions/:id", get(get_share_session))
        .route("/api/v1/share-sessions/:id/stop", post(stop_share_session))
        .layer(cors)
        .with_state(state);

    let addr = "127.0.0.1:8080".parse::<std::net::SocketAddr>()?;
    
    tracing::info!("🚀 ForgeFit Backend listening on {}", addr);
    
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}

async fn health_check() -> impl IntoResponse {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "forgefit-backend",
        "version": env!("CARGO_PKG_VERSION")
    }))
}

async fn get_exercises(State(state): State<AppState>) -> Result<Json<Vec<Exercise>>, AppError> {
    let exercises = sqlx::query_as::<_, Exercise>(
        "SELECT id, name, muscle, category, description FROM exercises ORDER BY name"
    )
    .fetch_all(&state.db)
    .await?;

    Ok(Json(exercises))
}

async fn get_muscle_map(State(state): State<AppState>) -> Result<Json<MuscleMap>, AppError> {
    let muscle_volumes = sqlx::query(
        "SELECT muscle, SUM(volume) as total_volume, COUNT(*) as exercise_count 
         FROM (
             SELECT e.muscle, COUNT(w.id) as volume
             FROM exercises e
             LEFT JOIN workouts w ON w.exercise_name = e.name
             GROUP BY e.id, e.muscle
         )
         GROUP BY muscle"
    )
    .fetch_all(&state.db)
    .await?;

    let mut muscles = Vec::new();
    for row in muscle_volumes {
        muscles.push(MuscleVolume {
            muscle: row.try_get("muscle")?,
            volume: row.try_get::<i64, _>("total_volume")? as u32,
            exercise_count: row.try_get::<i64, _>("exercise_count")? as u32,
        });
    }

    Ok(Json(MuscleMap { muscles }))
}

async fn get_diet_today(State(state): State<AppState>) -> Result<Json<DietPlanWithMeals>, AppError> {
    let today = chrono::Local::now().format("%Y-%m-%d").to_string();
    
    let plan = sqlx::query_as::<_, DietPlan>(
        "SELECT id, date, total_calories, protein_g, carbs_g, fat_g FROM diet_plans WHERE date = ? LIMIT 1"
    )
    .bind(&today)
    .fetch_optional(&state.db)
    .await?;

    if let Some(plan) = plan {
        let meals = sqlx::query_as::<_, Meal>(
            "SELECT id, diet_plan_id, meal_type, name, calories, protein_g, carbs_g, fat_g, description 
             FROM meals WHERE diet_plan_id = ?"
        )
        .bind(&plan.id)
        .fetch_all(&state.db)
        .await?;
        
        Ok(Json(DietPlanWithMeals { plan, meals }))
    } else {
        let default_plan = sqlx::query_as::<_, DietPlan>(
            "SELECT id, date, total_calories, protein_g, carbs_g, fat_g FROM diet_plans LIMIT 1"
        )
        .fetch_one(&state.db)
        .await?;
        
        let meals = sqlx::query_as::<_, Meal>(
            "SELECT id, diet_plan_id, meal_type, name, calories, protein_g, carbs_g, fat_g, description 
             FROM meals WHERE diet_plan_id = ?"
        )
        .bind(&default_plan.id)
        .fetch_all(&state.db)
        .await?;
        
        Ok(Json(DietPlanWithMeals { plan: default_plan, meals }))
    }
}

async fn get_diet_plans(State(state): State<AppState>) -> Result<Json<Vec<DietPlan>>, AppError> {
    let plans = sqlx::query_as::<_, DietPlan>(
        "SELECT id, date, total_calories, protein_g, carbs_g, fat_g FROM diet_plans ORDER BY date DESC LIMIT 30"
    )
    .fetch_all(&state.db)
    .await?;

    Ok(Json(plans))
}

async fn create_workout(
    State(state): State<AppState>,
    Json(workout): Json<CreateWorkoutRequest>,
) -> Result<Json<Workout>, AppError> {
    let id = uuid::Uuid::new_v4().to_string();
    let created_at = chrono::Utc::now().to_rfc3339();

    sqlx::query(
        "INSERT INTO workouts (id, exercise_name, sets, reps, weight_kg, notes, created_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?)"
    )
    .bind(&id)
    .bind(&workout.exercise_name)
    .bind(workout.sets)
    .bind(workout.reps)
    .bind(workout.weight_kg)
    .bind(&workout.notes)
    .bind(&created_at)
    .execute(&state.db)
    .await?;

    let created = sqlx::query_as::<_, Workout>(
        "SELECT id, exercise_name, sets, reps, weight_kg, notes, created_at FROM workouts WHERE id = ?"
    )
    .bind(&id)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(created))
}

async fn get_workouts(State(state): State<AppState>) -> Result<Json<Vec<Workout>>, AppError> {
    let workouts = sqlx::query_as::<_, Workout>(
        "SELECT id, exercise_name, sets, reps, weight_kg, notes, created_at FROM workouts ORDER BY created_at DESC LIMIT 100"
    )
    .fetch_all(&state.db)
    .await?;

    Ok(Json(workouts))
}

async fn get_workout_by_id(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Workout>, AppError> {
    let workout = sqlx::query_as::<_, Workout>(
        "SELECT id, exercise_name, sets, reps, weight_kg, notes, created_at FROM workouts WHERE id = ?"
    )
    .bind(&id)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(workout))
}

async fn create_share_session(
    State(state): State<AppState>,
    Json(req): Json<CreateShareSessionRequest>,
) -> Result<Json<ShareSession>, AppError> {
    let id = uuid::Uuid::new_v4().to_string();
    let started_at = chrono::Utc::now().to_rfc3339();

    sqlx::query(
        "INSERT INTO share_sessions (id, title, status, started_at) VALUES (?, ?, ?, ?)"
    )
    .bind(&id)
    .bind(&req.title)
    .bind("active")
    .bind(&started_at)
    .execute(&state.db)
    .await?;

    let session = sqlx::query_as::<_, ShareSession>(
        "SELECT id, title, status, started_at, stopped_at FROM share_sessions WHERE id = ?"
    )
    .bind(&id)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(session))
}

async fn get_share_session(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<ShareSession>, AppError> {
    let session = sqlx::query_as::<_, ShareSession>(
        "SELECT id, title, status, started_at, stopped_at FROM share_sessions WHERE id = ?"
    )
    .bind(&id)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(session))
}

async fn stop_share_session(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<ShareSession>, AppError> {
    let stopped_at = chrono::Utc::now().to_rfc3339();

    sqlx::query(
        "UPDATE share_sessions SET status = ?, stopped_at = ? WHERE id = ?"
    )
    .bind("stopped")
    .bind(&stopped_at)
    .bind(&id)
    .execute(&state.db)
    .await?;

    let session = sqlx::query_as::<_, ShareSession>(
        "SELECT id, title, status, started_at, stopped_at FROM share_sessions WHERE id = ?"
    )
    .bind(&id)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(session))
}

struct AppError(anyhow::Error);

impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({
                "error": self.0.to_string()
            })),
        )
            .into_response()
    }
}

impl<E> From<E> for AppError
where
    E: Into<anyhow::Error>,
{
    fn from(err: E) -> Self {
        Self(err.into())
    }
}

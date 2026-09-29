#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::SqlitePool;

    async fn setup_test_db() -> SqlitePool {
        let pool = SqlitePool::connect("sqlite::memory:")
            .await
            .expect("Failed to create test database");
        
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .expect("Failed to run migrations");
        
        crate::seed::seed_database(&pool)
            .await
            .expect("Failed to seed database");
        
        pool
    }

    #[tokio::test]
    async fn test_exercises_are_seeded() {
        let pool = setup_test_db().await;
        
        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM exercises")
            .fetch_one(&pool)
            .await
            .expect("Failed to count exercises");
        
        assert_eq!(count, 10, "Should have 10 featured exercises");
    }

    #[tokio::test]
    async fn test_exercises_have_correct_muscles() {
        let pool = setup_test_db().await;
        
        let chest_exercises: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM exercises WHERE muscle = 'chest'"
        )
        .fetch_one(&pool)
        .await
        .expect("Failed to query chest exercises");
        
        assert_eq!(chest_exercises, 1, "Should have 1 chest exercise (Bench Press)");
        
        let back_exercises: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM exercises WHERE muscle = 'back'"
        )
        .fetch_one(&pool)
        .await
        .expect("Failed to query back exercises");
        
        assert_eq!(back_exercises, 2, "Should have 2 back exercises (Pull-ups, Rows)");
    }

    #[tokio::test]
    async fn test_diet_plan_is_seeded() {
        let pool = setup_test_db().await;
        
        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM diet_plans")
            .fetch_one(&pool)
            .await
            .expect("Failed to count diet plans");
        
        assert!(count >= 1, "Should have at least 1 diet plan");
    }

    #[tokio::test]
    async fn test_diet_plan_has_meals() {
        let pool = setup_test_db().await;
        
        let meal_count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM meals")
            .fetch_one(&pool)
            .await
            .expect("Failed to count meals");
        
        assert_eq!(meal_count, 4, "Should have 4 meals (breakfast, lunch, dinner, snack)");
    }

    #[tokio::test]
    async fn test_workout_crud() {
        let pool = setup_test_db().await;
        let id = uuid::Uuid::new_v4().to_string();
        let created_at = chrono::Utc::now().to_rfc3339();
        
        sqlx::query(
            "INSERT INTO workouts (id, exercise_name, sets, reps, weight_kg, notes, created_at) 
             VALUES (?, ?, ?, ?, ?, ?, ?)"
        )
        .bind(&id)
        .bind("Bench Press")
        .bind(4)
        .bind(8)
        .bind(80.0)
        .bind("Test workout")
        .bind(&created_at)
        .execute(&pool)
        .await
        .expect("Failed to insert workout");
        
        let workout: crate::models::Workout = sqlx::query_as(
            "SELECT id, exercise_name, sets, reps, weight_kg, notes, created_at FROM workouts WHERE id = ?"
        )
        .bind(&id)
        .fetch_one(&pool)
        .await
        .expect("Failed to fetch workout");
        
        assert_eq!(workout.exercise_name, "Bench Press");
        assert_eq!(workout.sets, 4);
        assert_eq!(workout.reps, 8);
        assert_eq!(workout.weight_kg, 80.0);
    }

    #[tokio::test]
    async fn test_share_session_lifecycle() {
        let pool = setup_test_db().await;
        let id = uuid::Uuid::new_v4().to_string();
        let started_at = chrono::Utc::now().to_rfc3339();
        
        sqlx::query(
            "INSERT INTO share_sessions (id, title, status, started_at) VALUES (?, ?, ?, ?)"
        )
        .bind(&id)
        .bind("Test Session")
        .bind("active")
        .bind(&started_at)
        .execute(&pool)
        .await
        .expect("Failed to insert share session");
        
        let session: crate::models::ShareSession = sqlx::query_as(
            "SELECT id, title, status, started_at, stopped_at FROM share_sessions WHERE id = ?"
        )
        .bind(&id)
        .fetch_one(&pool)
        .await
        .expect("Failed to fetch share session");
        
        assert_eq!(session.status, "active");
        assert!(session.stopped_at.is_none());
        
        let stopped_at = chrono::Utc::now().to_rfc3339();
        sqlx::query(
            "UPDATE share_sessions SET status = ?, stopped_at = ? WHERE id = ?"
        )
        .bind("stopped")
        .bind(&stopped_at)
        .bind(&id)
        .execute(&pool)
        .await
        .expect("Failed to update share session");
        
        let updated_session: crate::models::ShareSession = sqlx::query_as(
            "SELECT id, title, status, started_at, stopped_at FROM share_sessions WHERE id = ?"
        )
        .bind(&id)
        .fetch_one(&pool)
        .await
        .expect("Failed to fetch updated share session");
        
        assert_eq!(updated_session.status, "stopped");
        assert!(updated_session.stopped_at.is_some());
    }
}

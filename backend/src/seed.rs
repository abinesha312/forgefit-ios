use sqlx::SqlitePool;
use uuid::Uuid;

pub async fn seed_database(pool: &SqlitePool) -> anyhow::Result<()> {
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM exercises")
        .fetch_one(pool)
        .await?;

    if count > 0 {
        tracing::info!("Database already seeded, skipping");
        return Ok(());
    }

    tracing::info!("Seeding database with featured exercises...");

    let featured_exercises = vec![
        ("bench-press", "Bench Press", "chest", "compound", 
         "Lie on a flat bench and press the barbell from chest to full arm extension. Lower with control."),
        ("overhead-press", "Overhead Press", "shoulders", "compound",
         "Press the barbell overhead from shoulder height to full lockout. Keep core tight."),
        ("pull-ups", "Pull-ups", "back", "compound",
         "Hang from a bar with hands shoulder-width apart. Pull your body up until chin is over the bar."),
        ("rows", "Barbell Rows", "back", "compound",
         "Bend at the hips and pull the barbell to your lower chest. Keep your back straight."),
        ("squats", "Squats", "quads", "compound",
         "Stand with barbell on upper back. Squat down until thighs are parallel to ground, then drive up."),
        ("romanian-deadlift", "Romanian Deadlift", "hamstrings", "compound",
         "Hold barbell at hip level. Hinge at hips, lowering the bar while keeping legs slightly bent."),
        ("lunges", "Lunges", "glutes", "compound",
         "Step forward into a lunge position, lowering your hips until both knees are at 90 degrees."),
        ("plank", "Plank", "core", "bodyweight",
         "Hold a push-up position on your forearms, keeping your body in a straight line."),
        ("calf-raises", "Calf Raises", "calves", "isolation",
         "Stand on the edge of a step. Rise up on your toes, then lower your heels below the step level."),
        ("face-pulls", "Face Pulls", "rear delts", "isolation",
         "Pull the rope attachment toward your face, separating the rope at the end. Focus on rear delts."),
    ];

    for (id, name, muscle, category, description) in featured_exercises {
        sqlx::query(
            "INSERT INTO exercises (id, name, muscle, category, description) VALUES (?, ?, ?, ?, ?)"
        )
        .bind(id)
        .bind(name)
        .bind(muscle)
        .bind(category)
        .bind(description)
        .execute(pool)
        .await?;
    }

    tracing::info!("Seeding sample diet plan...");
    
    let today = chrono::Local::now().format("%Y-%m-%d").to_string();
    let diet_plan_id = Uuid::new_v4().to_string();

    sqlx::query(
        "INSERT INTO diet_plans (id, date, total_calories, protein_g, carbs_g, fat_g) 
         VALUES (?, ?, ?, ?, ?, ?)"
    )
    .bind(&diet_plan_id)
    .bind(&today)
    .bind(2400)
    .bind(180)
    .bind(250)
    .bind(70)
    .execute(pool)
    .await?;

    let meals = vec![
        ("breakfast", "Protein Oatmeal Bowl", 520, 35, 65, 15,
         "Oats with whey protein, banana, berries, and almond butter"),
        ("lunch", "Grilled Chicken & Rice", 680, 55, 75, 18,
         "Grilled chicken breast, brown rice, broccoli, olive oil"),
        ("dinner", "Salmon & Sweet Potato", 720, 50, 70, 25,
         "Baked salmon, roasted sweet potato, asparagus, avocado"),
        ("snack", "Greek Yogurt & Nuts", 480, 40, 40, 12,
         "Greek yogurt, mixed berries, almonds, honey"),
    ];

    for (meal_type, name, calories, protein, carbs, fat, description) in meals {
        let meal_id = Uuid::new_v4().to_string();
        sqlx::query(
            "INSERT INTO meals (id, diet_plan_id, meal_type, name, calories, protein_g, carbs_g, fat_g, description) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        )
        .bind(meal_id)
        .bind(&diet_plan_id)
        .bind(meal_type)
        .bind(name)
        .bind(calories)
        .bind(protein)
        .bind(carbs)
        .bind(fat)
        .bind(description)
        .execute(pool)
        .await?;
    }

    tracing::info!("✅ Database seeded successfully");

    Ok(())
}

-- Exercises table
CREATE TABLE IF NOT EXISTS exercises (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    muscle TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL
);

-- Diet plans table
CREATE TABLE IF NOT EXISTS diet_plans (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL,
    total_calories INTEGER NOT NULL,
    protein_g INTEGER NOT NULL,
    carbs_g INTEGER NOT NULL,
    fat_g INTEGER NOT NULL
);

-- Meals table
CREATE TABLE IF NOT EXISTS meals (
    id TEXT PRIMARY KEY,
    diet_plan_id TEXT NOT NULL,
    meal_type TEXT NOT NULL,
    name TEXT NOT NULL,
    calories INTEGER NOT NULL,
    protein_g INTEGER NOT NULL,
    carbs_g INTEGER NOT NULL,
    fat_g INTEGER NOT NULL,
    description TEXT NOT NULL,
    FOREIGN KEY (diet_plan_id) REFERENCES diet_plans(id)
);

-- Workouts table
CREATE TABLE IF NOT EXISTS workouts (
    id TEXT PRIMARY KEY,
    exercise_name TEXT NOT NULL,
    sets INTEGER NOT NULL,
    reps INTEGER NOT NULL,
    weight_kg REAL NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL
);

-- Share sessions table
CREATE TABLE IF NOT EXISTS share_sessions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT NOT NULL,
    started_at TEXT NOT NULL,
    stopped_at TEXT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_exercises_muscle ON exercises(muscle);
CREATE INDEX IF NOT EXISTS idx_diet_plans_date ON diet_plans(date);
CREATE INDEX IF NOT EXISTS idx_meals_diet_plan ON meals(diet_plan_id);
CREATE INDEX IF NOT EXISTS idx_workouts_created ON workouts(created_at);
CREATE INDEX IF NOT EXISTS idx_share_sessions_status ON share_sessions(status);

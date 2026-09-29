# ForgeFit Backend

Rust backend service for ForgeFit iOS app providing workout tracking, muscle mapping, diet plans, and screen sharing session management.

## Tech Stack

- **Axum** - Web framework
- **Tokio** - Async runtime
- **SQLite** (via sqlx) - Database
- **Serde** - JSON serialization

## Features

### API Endpoints

#### Health Check
- `GET /health` - Service health status

#### Exercises
- `GET /api/v1/exercises` - List all featured exercises (10 core movements)
  - Each exercise includes: id, name, muscle group, category, description

#### Muscle Map
- `GET /api/v1/muscle-map` - Aggregate muscle volume/activity data
  - Returns workout volume and exercise count per muscle group

#### Diet Plans
- `GET /api/v1/diet/today` - Today's diet plan with meals
- `GET /api/v1/diet/plans` - Recent diet plans (last 30 days)

Each diet plan includes:
- Total macros: calories, protein, carbs, fat
- Individual meals (breakfast, lunch, dinner, snacks)

#### Workouts
- `POST /api/v1/workouts` - Log a workout session
- `GET /api/v1/workouts` - Get recent workouts (last 100)
- `GET /api/v1/workouts/:id` - Get specific workout by ID

#### Screen Share Sessions
- `POST /api/v1/share-sessions` - Start a new coach/share session
- `GET /api/v1/share-sessions/:id` - Get session details
- `POST /api/v1/share-sessions/:id/stop` - Stop an active session

## Featured Exercises (Seed Data)

The backend seeds these 10 core exercises on first run:

1. **Bench Press** → Chest
2. **Overhead Press** → Shoulders
3. **Pull-ups** → Back
4. **Rows** → Back
5. **Squats** → Quads
6. **Romanian Deadlift** → Hamstrings
7. **Lunges** → Glutes
8. **Plank** → Core
9. **Calf Raises** → Calves
10. **Face Pulls** → Rear Delts

## Getting Started

### Prerequisites

- Rust 1.70+ (`rustup` recommended)
- SQLite (bundled with sqlx)

### Running the Server

```bash
# From backend/ directory
cargo run
```

The server will:
1. Create `forgefit.db` SQLite database
2. Run migrations
3. Seed featured exercises and sample diet plan
4. Start listening on `http://127.0.0.1:8080`

### Environment Variables

```bash
# Optional: custom database location
DATABASE_URL=sqlite:./custom.db

# Optional: logging level
RUST_LOG=debug
```

### Development

```bash
# Check code without running
cargo check

# Run with detailed logs
RUST_LOG=debug cargo run

# Build release binary
cargo build --release
```

## Testing

```bash
# Run all tests
cargo test

# Run tests with output
cargo test -- --nocapture

# Run specific test
cargo test test_health_check
```

### Example Test Requests

```bash
# Health check
curl http://127.0.0.1:8080/health

# Get exercises
curl http://127.0.0.1:8080/api/v1/exercises

# Get muscle map
curl http://127.0.0.1:8080/api/v1/muscle-map

# Get today's diet
curl http://127.0.0.1:8080/api/v1/diet/today

# Log a workout
curl -X POST http://127.0.0.1:8080/api/v1/workouts \
  -H "Content-Type: application/json" \
  -d '{
    "exercise_name": "Bench Press",
    "sets": 4,
    "reps": 8,
    "weight_kg": 80.0,
    "notes": "Felt strong today"
  }'

# Start a share session
curl -X POST http://127.0.0.1:8080/api/v1/share-sessions \
  -H "Content-Type: application/json" \
  -d '{"title": "Morning Chest Workout"}'
```

## CORS

The server has CORS configured to allow all origins for local development. This enables the iOS simulator (running on `http://127.0.0.1:*` or `localhost`) to connect.

For production, restrict CORS to specific origins.

## Database Schema

### Tables

- **exercises** - Featured exercise library
- **diet_plans** - Daily nutrition plans
- **meals** - Individual meals within diet plans
- **workouts** - Logged workout sessions
- **share_sessions** - Screen sharing/coach mode sessions

All tables use TEXT-based UUIDs as primary keys for simplicity and portability.

## Architecture

```
src/
├── main.rs       # Axum server, routes, handlers
├── models.rs     # Data models (Serde + SQLx)
└── seed.rs       # Database seeding logic

migrations/
└── 001_init.sql  # Database schema
```

## Future Enhancements

- [ ] User authentication (JWT)
- [ ] WebSocket support for live workout updates
- [ ] Video storage/streaming for screen shares
- [ ] Advanced analytics and charts
- [ ] PostgreSQL option for production

## License

MIT - See root LICENSE file

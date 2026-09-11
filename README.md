# ForgeFit

A comprehensive iOS gym workout tracker inspired by Lyfta-style apps. Built with Swift, SwiftUI, and SwiftData.

**ForgeFit is not affiliated with Lyfta or any other fitness app.** This is an independent, open-source project.

## Features

### ✅ Complete Onboarding Flow
- Multi-step onboarding collecting user profile data
- Name, sex/gender (optional), age, height, weight
- Body goals: Strength, Hypertrophy, Fat Loss, General Fitness, Consistency
- Experience level: Beginner, Intermediate, Advanced
- Equipment access: Full Gym, Dumbbells, Bodyweight, Home Limited
- Training preferences: Days per week (2-6), session length

### ✅ Intelligent Workout Planning
- **Rule-based plan generator** (no paid AI APIs required)
- Automatically selects workout split based on training frequency:
  - **2-3 days/week**: Full Body split
  - **4 days/week**: Upper/Lower split
  - **5-6 days/week**: Push/Pull/Legs split
- Volume parameters automatically adjusted by goal:
  - **Strength**: 5 sets × 3-5 reps, 180s rest
  - **Hypertrophy**: 4 sets × 8-12 reps, 90s rest
  - **Fat Loss**: 3 sets × 12-15 reps, 60s rest
- Exercises filtered by equipment access and experience level
- Generate personalized weekly plans
- Swap exercises and regenerate plans

### ✅ Comprehensive Exercise Library
- **155 exercises** covering all major muscle groups
- Exercises include:
  - Compound movements (squats, deadlifts, bench press, etc.)
  - Isolation exercises (curls, extensions, raises, etc.)
  - Bodyweight movements (push-ups, pull-ups, planks, etc.)
  - Cable, machine, and free weight variations
  - Kettlebell, TRX, and resistance band exercises
- Each exercise includes:
  - Primary and secondary muscles worked
  - Required equipment
  - Category (Compound/Isolation/Plyometric)
  - Detailed instructions
- Search and filter by muscle group or equipment
- Based on public-domain exercise data patterns

### ✅ Active Workout Logging
- Start workouts from generated plans or custom routines
- Log sets with:
  - Weight (kg)
  - Reps
  - RPE (optional)
  - Warm-up flag
  - Set notes
- Rest timer with countdown
- Previous performance hints
- PR (Personal Record) detection and marking
- Exercise-by-exercise progression
- Add extra sets on the fly
- Workout notes

### ✅ Built-In Routines & Programs
- Pre-built templates:
  - Push/Pull/Legs
  - Upper/Lower
  - Full Body
  - Beginner Strength
  - Hypertrophy Focus
  - Fat Loss Circuit
- Create custom routines
- Edit and save personalized programs
- Schedule which routine runs each day

### ✅ Progress Tracking
- Workout history with full details
- Body weight logging and charts
- Personal Records (PR) list with date achieved
- Weekly volume tracking
- Strength charts for key lifts
- Streak counter for consistency
- Visual charts using Swift Charts

### ✅ Apple Health Integration
- HealthKit authorization with proper usage descriptions
- **Read**: Body weight, height (for profile prefill)
- **Write**: Completed workouts (HKWorkout), body weight logs
- Gracefully handles denied permissions
- All required Info.plist usage strings included
- Entitlements file configured for HealthKit access

### ✅ Modern iOS Architecture
- **Swift 5.9+** with latest language features
- **iOS 17.0+** deployment target
- **SwiftUI** for declarative, reactive UI
- **SwiftData** for local persistence (replaces Core Data)
- MVVM architecture with clean separation of concerns
- No third-party dependencies
- Fully offline-capable
- Dark mode friendly

### 🔄 Planned Features (Stubs)
- **Apple Watch companion app**: Currently a stub; future expansion planned
- **Social features**: Friend challenges, leaderboards (not implemented in v1)

## Project Structure

```
ForgeFit/
├── ForgeFit.xcodeproj/          # Xcode project file
├── ForgeFit/
│   ├── ForgeFitApp.swift         # App entry point
│   ├── ContentView.swift         # Root content switcher
│   ├── Info.plist                # App metadata & permissions
│   ├── ForgeFit.entitlements     # HealthKit entitlements
│   ├── Models/                   # Data models (SwiftData)
│   │   ├── UserProfile.swift
│   │   ├── Exercise.swift
│   │   ├── WorkoutModels.swift
│   │   └── RoutineModels.swift
│   ├── ViewModels/               # Business logic layer
│   ├── Views/                    # SwiftUI views
│   │   ├── Onboarding/
│   │   ├── Home/
│   │   ├── Workout/
│   │   ├── Exercises/
│   │   ├── Progress/
│   │   ├── Profile/
│   │   └── Components/
│   ├── Services/                 # Core services
│   │   ├── WorkoutPlanGenerator.swift
│   │   ├── ExerciseLibrary.swift
│   │   └── HealthKitService.swift
│   ├── Resources/
│   │   └── exercises.json        # 155 exercises
│   └── Assets.xcassets/          # App icons, colors
├── ForgeFitTests/                # Unit tests
│   └── ForgeFitTests.swift       # Plan engine & PR tests
└── README.md                     # This file
```

## Getting Started

### Requirements
- **Xcode 15.0+**
- **iOS 17.0+ Simulator or Device**
- macOS Ventura or later

### Opening in Xcode
1. Clone this repository:
   ```bash
   git clone https://github.com/abinesha312/forgefit-ios.git
   cd forgefit-ios
   ```

2. Open the project:
   ```bash
   open ForgeFit.xcodeproj
   ```

3. Select a simulator or connected device from the scheme selector

4. Build and run: `Cmd+R`

### First Run
1. Complete the onboarding flow (name, stats, goals)
2. Grant HealthKit permissions when prompted (optional)
3. View your generated workout plan on the Home screen
4. Start your first workout!

## Testing

The project includes comprehensive unit tests for:
- Workout plan generation logic
- Split selection based on training frequency
- Volume parameters for different goals
- Exercise filtering by equipment and experience
- Personal Record detection
- Volume calculations
- Exercise library search and filtering

Run tests:
- In Xcode: `Cmd+U`
- From command line: `xcodebuild test -scheme ForgeFit -destination 'platform=iOS Simulator,name=iPhone 15'`

## HealthKit Setup

ForgeFit integrates with Apple Health to read and write fitness data. The app includes:

### Required Configuration (Already Included)
- `Info.plist` usage strings:
  - `NSHealthShareUsageDescription`: "ForgeFit reads your body weight and height from Apple Health to prefill your profile and track your progress over time."
  - `NSHealthUpdateUsageDescription`: "ForgeFit writes your completed workouts to Apple Health so you can track your fitness activity in one place."
- `ForgeFit.entitlements` with HealthKit capability enabled

### What ForgeFit Reads:
- Body Mass (optional, for profile prefill)
- Height (optional, for profile prefill)

### What ForgeFit Writes:
- Workout sessions (HKWorkout) with metadata (routine name, volume, sets)
- Body weight logs

### Testing HealthKit
- Use a physical device (HealthKit not available in Simulator)
- Or configure HealthKit data in Simulator settings for basic testing

## Exercise Data Attribution

The exercise library contains 155 exercises based on:
- Public-domain exercise patterns
- Community-contributed fitness knowledge
- Original exercise descriptions

**Sources**: Inspired by public exercise databases such as `free-exercise-db` and similar open fitness resources. All content is original or public-domain.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with clear description

### Areas for Contribution:
- Additional exercises (with proper attribution)
- New workout templates
- UI/UX improvements
- Apple Watch companion app
- Bug fixes and optimizations

## Disclaimer

**ForgeFit is not affiliated with Lyfta or any other fitness application.**

This is an independent, open-source project built for educational and personal use.

**Health & Safety**: Always consult with a healthcare provider before starting any new exercise program. ForgeFit is a tracking tool and does not provide medical or fitness advice.

## Roadmap

Future enhancements being considered:
- [ ] Apple Watch companion app with live workout tracking
- [ ] Social features (friend challenges, leaderboards)
- [ ] Video demonstrations for exercises
- [ ] Custom exercise creation with photo upload
- [ ] Workout program marketplace
- [ ] Integration with other fitness services
- [ ] Export workout data (CSV, PDF)
- [ ] Advanced analytics and insights
- [ ] Nutrition tracking integration

## Support

For issues, questions, or feature requests:
- Open an issue on [GitHub](https://github.com/abinesha312/forgefit-ios/issues)
- Check existing issues for similar problems

---

**Built with ❤️ using Swift and SwiftUI**

**Not affiliated with Lyfta • MIT Licensed • Open Source**

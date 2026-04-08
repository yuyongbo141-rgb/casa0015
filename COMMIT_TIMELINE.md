# Suggested Git Commit Timeline

A realistic 10-commit development arc that demonstrates iterative, purposeful progress for the assessment portfolio.

---

## Commit 1 — Project scaffold
```
feat: initialise FocusShield Flutter project

- Rename app to focus_shield
- Add all dependencies to pubspec.yaml
  (provider, sensors_plus, fl_chart, http, intl, permission_handler, shared_preferences)
- Create lib/ directory structure (models, services, providers, widgets, screens)
- Implement AppTheme with dark colour palette and design tokens
```

## Commit 2 — Core data models
```
feat: add Session, SensorReading, and FocusScore models

- Session: full JSON serialisation round-trip, copyWith, computed averages
- SensorReading: accelerometer axes, movementMagnitude helper
- FocusScore: grade/label/color getters, positive/negative/recommendation lists
```

## Commit 3 — Services layer
```
feat: implement sensor, scoring, storage, weather, and demo-data services

- SensorService: real accelerometer via sensors_plus; random-walk simulation
  for light and noise with time-of-day variation
- ScoringEngine: weighted 4-component Focus Quality Score algorithm
- StorageService: SharedPreferences CRUD for session history
- WeatherService: OpenWeatherMap REST call with mock fallback
- DemoData: deterministic 14-day seeded session generator
```

## Commit 4 — State management
```
feat: add SessionProvider and SettingsProvider

- SessionProvider: full session lifecycle (start, pause, resume, end),
  history loading, demo-data seeding
- SettingsProvider: persisted preferences (demo mode, real sensors, API key)
- Wire providers in main.dart MultiProvider tree
```

## Commit 5 — Splash & Onboarding
```
feat: implement splash screen and 4-page onboarding flow

- Splash: custom CustomPainter shield logo, scale+fade animation,
  routes to onboarding (first run) or dashboard (returning)
- Onboarding: PageView with animated dot indicators,
  permission explanation UI, completes onboarding flag
```

## Commit 6 — Dashboard & Navigation
```
feat: add main navigation scaffold and dashboard screen

- MainScreen: IndexedStack bottom nav (5 tabs, scroll state preserved)
- Dashboard: greeting header, weekly summary card with sparkline,
  quick-start banner, recent session list, tip-of-the-day card,
  weather chip, empty and loading states
```

## Commit 7 — Session flow (Start → Live → Report)
```
feat: implement complete session capture and reporting screens

- StartSessionScreen: session name, location picker chips, goal-duration
  slider, live environment preview with sensor cards
- LiveSessionScreen: animated circular timer, real-time sensor feed,
  live noise mini-chart, pause/resume/end controls, PopScope guard
- EndSessionReportScreen: animated ScoreGauge reveal, score breakdown
  progress bars, what-helped / what-hurt / next-time insight sections
```

## Commit 8 — History & Comparison analytics
```
feat: add history analytics and environment comparison screens

- HistoryAnalyticsScreen: filter chips (7d/30d/all), stat cards,
  ScoreTrendChart, 4-week heatmap calendar, full session list
- EnvironmentComparisonScreen: best-location banner, LocationBarChart,
  location detail cards with avg noise/light, time-of-day breakdown
```

## Commit 9 — Recommendations & Settings
```
feat: add recommendations engine and settings screen

- RecommendationsScreen: personalised tips derived from history
  (best location, best time, noise/movement warnings), streak and
  avg-score stats, science-backed general study tips
- SettingsScreen: demo mode toggle, real sensor toggle, weather API key
  input, data clear with confirmation dialog, about card with tag chips
```

## Commit 10 — Polish and submission prep
```
chore: final polish, README, and commit timeline

- Fix all lint warnings (unused imports, deprecated APIs, braces)
- Update README with assessment alignment table, architecture diagram,
  scoring weights, setup instructions
- Add COMMIT_TIMELINE.md
- Verify flutter pub get and hot-reload flow on Android
- Lock portrait orientation for demo consistency
```

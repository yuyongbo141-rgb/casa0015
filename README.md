# FocusShield

> **CASA Connected Environment — Mobile App Assessment**
> A Flutter application that helps students discover and improve the quality of their study environment by fusing on-device sensor data with external contextual information.

---

## Project Rationale

Modern students face a hidden productivity problem: most know _when_ they study, but few understand _how their environment affects_ their concentration. FocusShield makes the invisible visible — transforming raw sensor signals from the phone in their pocket into actionable insights about noise, lighting, and physical disturbance.

The app fits squarely within the "connected environment" theme: a personal sensor node (the phone) captures the local physical world; an external weather API adds contextual richness; and a scoring engine synthesises everything into a narrative the user can act on.

---

## Assessment Alignment

| Criterion | Implementation |
|---|---|
| **Multiple views with clear narrative** | 10 screens (splash → onboarding → dashboard → start → live session → report → history → compare → tips → settings) forming a coherent study-tracking story |
| **Onboard sensors** | `sensors_plus` accelerometer (real data); ambient light and noise simulated with realistic random-walk model and graceful fallback |
| **Logs data over time** | `SharedPreferences` JSON persistence; session history with time-stamped sensor readings |
| **External API / service** | OpenWeatherMap weather; configurable API key; deterministic mock fallback so demo always works offline |
| **Designed for repeated engagement** | Streaks, heatmap calendar, weekly trend chart, personalised recommendations that deepen with more sessions |
| **Strong UI/UX** | Animated score gauge, live sensor cards with score bars, fl_chart line and bar charts, filter chips, animated transitions, comprehensive empty/loading/error states |
| **Splash screen** | Custom `CustomPainter` shield logo with scale + fade animation |
| **Permissions** | Onboarding permission UX (mic + motion); runtime handled via `permission_handler` |
| **Clean architecture** | Models / Services / Providers / Widgets / Screens — clear layer separation |
| **Seeded demo data** | 14 days x 1-2 sessions of realistic data generated from fixed seed on first launch |

---

## Architecture

```
lib/
├── main.dart              # App entry, Provider tree, orientation lock
├── app.dart               # MaterialApp, route table
├── theme/
│   └── app_theme.dart     # Centralised design tokens, ThemeData
├── models/
│   ├── session_model.dart # Session with JSON serialisation
│   ├── sensor_reading.dart
│   └── focus_score.dart
├── services/
│   ├── sensor_service.dart    # Accelerometer (real) + light/noise (simulated)
│   ├── scoring_engine.dart    # Focus Quality Score calculator
│   ├── storage_service.dart   # SharedPreferences CRUD
│   ├── weather_service.dart   # OpenWeatherMap + mock fallback
│   └── demo_data.dart         # 14-day seeded session generator
├── providers/
│   ├── session_provider.dart  # Session lifecycle + history state
│   └── settings_provider.dart # Persisted app preferences
├── widgets/
│   ├── score_gauge.dart    # Animated arc gauge (CustomPainter)
│   ├── sensor_card.dart    # Live sensor metric card
│   ├── session_card.dart   # History list item
│   └── focus_chart.dart    # Line, bar, and live sensor charts
└── screens/               # One file per screen (10 total)
```

### Focus Quality Score

Weighted composite of four sub-scores (each 0-100):

| Component | Weight | Signal |
|---|---|---|
| Noise     | 40 %   | Average dB over session; quiet < 40 dB = 100 pts |
| Movement  | 25 %   | Accelerometer deviation from gravitational rest |
| Light     | 20 %   | Optimal 300-600 lux; penalised below 100 or above 1000 |
| Duration  | 15 %   | Bonus for sustained sessions up to 90 min |

---

## Getting Started

### Prerequisites
- Flutter SDK >= 3.10
- Android device/emulator (iOS also supported; light sensor always simulated)

### Run

```bash
flutter pub get
flutter run
```

### Demo Mode
Demo Mode is **on by default** for first launch — 14 days of seeded sessions load automatically so all charts and recommendations are populated immediately. Toggle it off in Settings to start fresh.

### Optional: Real Weather
Add an OpenWeatherMap API key in **Settings -> Integrations**. The app functions fully without it using a deterministic mock.

### Platform Setup (for real microphone data)
To replace simulated noise with real microphone RMS, add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.HIGH_SAMPLING_RATE_SENSORS" />
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider`            | Lightweight state management |
| `sensors_plus`        | Accelerometer stream |
| `permission_handler`  | Runtime permissions |
| `shared_preferences`  | Local session persistence |
| `fl_chart`            | Line, bar, and sparkline charts |
| `http`                | Weather API calls |
| `intl`                | Date / number formatting |

---

## Future Improvements

- **Real microphone noise** — integrate `noise_meter` package for true dB estimation
- **Calendar reminder** — `flutter_local_notifications` for Pomodoro-style nudges
- **Library occupancy API** — UCL / campus room booking integration
- **iCloud / Google Drive sync** — optional cross-device history backup
- **ML pattern detection** — on-device TFLite model to predict ideal session windows
- **Wear OS / Apple Watch** — wrist-based disturbance detection

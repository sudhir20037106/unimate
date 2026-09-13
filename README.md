# UniMate — Student Study and Life Planner

A cross-platform mobile application built with Flutter for **ICT725 User
Experience and Mobile Application Development (Assessment 4)**, King's Own
Institute, T2 2026.

UniMate implements the front end of the high-fidelity prototype produced for
Assessment 3, extending it from a set of linked static frames into a working
application with persistent state, live analytics and an accessibility layer.

| | |
|---|---|
| **Author** | Sudhir Shrestha (Student ID 20037106) |
| **Subject** | ICT725 User Experience and Mobile Application Development |
| **Framework** | Flutter 3.x · Dart 3.x · Material 3 |
| **Figma prototype** | https://www.figma.com/design/EJ9BYcf4sSH5sgpL9DkRgI/UniMate-%E2%80%93-Student-Study---Life-Planner?node-id=0-1 |

---

## Implemented features

### 1. Task management (complete CRUD)
Create, read, update and delete assessment tasks with subject tagging, a three
level priority scale, an estimated-effort slider and a three state lifecycle
(`Pending → In Progress → Completed`). Tasks are grouped automatically into
*Overdue*, *Today*, *Tomorrow*, *This week*, *Later* and *Completed*, and can be
searched, filtered by status or subject, and sorted four ways. Deletion is by
swipe and is always reversible through an undo action.

### 2. Study planner with a Pomodoro focus timer
A full Pomodoro cycle — configurable focus interval, short break, and a long
break after every fourth interval — driven by a `Timer.periodic` ticker and
rendered with a `CustomPainter` progress ring. Completed focus intervals are
written back into the domain state as study sessions, so recorded effort feeds
the analytics automatically. Sessions can also be planned manually.

### 3. Class schedule
A weekly timetable with a horizontal day selector, per-day class counts, the
current day highlighted, and automatic detection of overlapping entries that is
surfaced as an inline warning on each affected card.

### 4. Progress analytics
Three visualisations derived from live state using `fl_chart`: a seven day focus
bar chart, an animated overall completion meter, and a per-subject donut with a
legend. Supporting metrics include the study streak and daily average.

### Cross-cutting engineering
* `provider` + `ChangeNotifier` state management with a repository abstraction.
* Persistence through `shared_preferences` with JSON serialisation.
* Light, dark and system theming seeded from the prototype colour `#4F46E5`.
* Accessibility: in-app text scaling (90–160 %), high contrast mode, reduce
  motion, semantic labels on every non-textual control, and ≥48 dp targets.
* Responsive shell: `NavigationBar` on handsets, `NavigationRail` from 720 dp.
* Animated route and tab transitions that honour the reduce-motion preference.

## Not yet implemented

Study Notes, push notifications and cloud synchronisation remain designed in the
prototype but are out of scope for a front-end-only assessment. See the report
for the rationale.

---

## Running the project

```bash
# 1. Clone
git clone <this-repository-url>
cd unimate

# 2. Generate the platform runners for your targets
#    (the repository tracks application source only)
flutter create . --platforms=android,ios,web

# 3. Install dependencies
flutter pub get

# 4. Run on a connected device or emulator
flutter run
```

To run the unit tests:

```bash
flutter test
```

## Project structure

```
lib/
├── main.dart                     # entry point, dependency injection
├── app.dart                      # MaterialApp, theming, text scaling
├── core/
│   ├── theme/app_theme.dart      # design tokens and ThemeData
│   └── utils/formatters.dart     # shared date and duration formatting
├── data/
│   ├── models/                   # StudyTask, StudySession, ClassEntry
│   └── repositories/             # LocalStore persistence layer
├── state/                        # PlannerController, PomodoroController,
│                                 # AuthController, SettingsController
└── ui/
    ├── screens/                  # 10 screens
    └── widgets/                  # AppCard, TaskCard, StatTile, ProgressRing…
```

## Academic integrity

This repository is submitted as individual assessment work for ICT725 at King's
Own Institute and complies with the KOI Academic Integrity Policy.

# GymTracker 🏋️‍♂️📱

GymTracker is a comprehensive, native iOS application designed to track workouts, monitor body metrics, and visualize your fitness journey. Built entirely with **Swift** and **SwiftUI**, it offers a premium, offline-first experience with advanced features like Live Activities and Google Sheets synchronization.

## ✨ Features

- **Workout Tracking:** Log your workouts, exercises, sets, reps, and weights with an intuitive interface. Keep track of what matters.
- **Exercise Library:** Access a built-in, categorized library of exercises to quickly build your routines.
- **Body Composition Tracking:** Detailed tracking of body weight and body fat percentage. It includes specific skinfold measurements (triceps, subscapular, abdominal, suprailiac, quadriceps, and calf) to calculate body fat precisely.
- **Session History:** Easily view and manage your complete history of past sessions, including highlighted metrics for total volume.
- **Progress Visualization:** Beautiful interactive charts that visualize your progress over time for individual exercises.
- **Rest & Cooldown Timers:** Integrated rest timers between sets to keep your workouts efficient.
- **Live Activities Support:** Keep track of your cooldown timers directly from the Lock Screen and Dynamic Island using iOS Live Activities.
- **Data Portability:** Robust data management allowing you to import/export your entire database as CSV files.
- **Google Sheets Sync:** Automatically back up and sync your workout data to a Google Sheet for ultimate portability and custom analysis.
- **Offline First:** Built on top of Core Data, ensuring your workouts are securely saved locally without requiring an internet connection.

## 🛠️ Technology Stack & Architecture

- **Platform:** iOS
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Local Database:** Core Data 
- **System Integrations:** ActivityKit & WidgetKit (for Live Activities)
- **Architecture:** MVVM-inspired component-based architecture using SwiftUI's declarative state management (`@State`, `@Binding`, `@Environment`, etc.)

## 🚀 Getting Started

To run the application locally on your machine or deploy it to your device:

### Prerequisites

- Mac running macOS (latest version recommended)
- **Xcode** 15 or later

### Installation

1. Clone the repository to your local machine.
2. Open the `GymTracker.xcodeproj` file in Xcode.
3. Select your target device (Simulator or a physical iPhone connected to your Mac).
4. Click the "Play" button or press `Cmd + R` to build and run the application.

*Note: For Live Activities and Google Sheets Sync, ensure you have the appropriate signing certificates and API tokens/Google Service accounts configured in your environment.*

## 📂 Project Structure

A quick overview of the key components inside the repository:
- `GymTracker/`: The main iOS application source code, including views, view models, managers, and Core Data models.
  - `GymTracker.xcdatamodeld`: Core Data schema defining Entities for Exercises, Workouts, Sets, Body Metrics, etc.
  - `Managers/`: Includes `CSVManager`, `RestCooldownManager`, `GoogleSheetsSyncManager`, orchestrating complex business logic decoupled from the views.
  - `Views/`: SwiftUI views for every screen (e.g., `ContentView`, `WorkoutListView`, `BodyMetricsView`, etc.).
- `CooldownLiveActivityExtension/`: Contains the widget extension for displaying the rest/cooldown timer on the lock screen and dynamic island.
- `GymTrackerTests/` & `GymTrackerUITests/`: Test target suites for robust validation.

## 🎨 Design System

GymTracker uses a custom `DesignSystem.swift` definition to maintain a unified aesthetic across the app, heavily leveraging modern design trends, iOS HIG (Human Interface Guidelines), and smooth micro-animations.

---

*Made with ❤️ for fitness enthusiasts.*

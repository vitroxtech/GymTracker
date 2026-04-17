import SwiftUI

@main
struct GymTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    WorkoutListView()
                }
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                
                NavigationStack {
                    SessionHistoryView()
                }
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                
                NavigationStack {
                    BodyMetricsView()
                }
                .tabItem {
                    Label("Metrics", systemImage: "figure.stand")
                }
                
                NavigationStack {
                    CSVDataView()
                }
                .tabItem {
                    Label("Data", systemImage: "arrow.up.doc.fill")
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

import SwiftUI

@main
struct GymTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            WorkoutListView().preferredColorScheme(.dark)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            
        }
    }
}

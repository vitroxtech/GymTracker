import SwiftUI

struct WorkoutListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.name, ascending: true)]
    ) private var workouts: FetchedResults<Workout>
    
    @State private var showingAddWorkout = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Top half: Workouts List
                    List {
                        ForEach(workouts) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                Text(workout.name ?? "Unnamed Workout")
                            }
                        }
                        .onDelete(perform: deleteWorkouts)
                    }
                    .frame(height: geo.size.height / 2)
                    
                    Divider()
                    
                    // Bottom half: Session History
                    SessionHistoryView()
                        .frame(height: geo.size.height / 2)
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWorkout = true }) {
                        Label("Add Workout", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func deleteWorkouts(at offsets: IndexSet) {
        offsets.map { workouts[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete workout: \(error.localizedDescription)")
        }
    }
}

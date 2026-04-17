import SwiftUI

struct WorkoutListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.name, ascending: true)]
    ) private var workouts: FetchedResults<Workout>
    
    @State private var showingAddWorkout = false
    
    var body: some View {
        List {
            Section(header: Text("My Workouts").sectionHeaderStyle()) {
                ForEach(workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.blue)
                            Text(workout.name ?? "Unnamed Workout")
                                .font(.headline)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteWorkouts)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Workouts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddWorkout = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            AddWorkoutView()
                .environment(\.managedObjectContext, viewContext)
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

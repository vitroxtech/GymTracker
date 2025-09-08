import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var workout: Workout

    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var showingAddExercise = false

    // Filter exercises by selected category or show all if none selected
    var filteredExercises: [Exercise] {
        if let category = selectedCategory {
            return workout.exercisesArray.filter { $0.categoryEnum == category }
        } else {
            return workout.exercisesArray
        }
    }

    // Unique categories available in the workout
    var availableCategories: [ExerciseCategory] {
        let categories = workout.exercisesArray.compactMap { $0.categoryEnum }
        return Array(Set(categories)).sorted(by: { $0.id < $1.id })
    }

    func hasSetToday(for exercise: Exercise) -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        guard let sets = exercise.setEntries as? Set<SetEntry> else { return false }

        return sets.contains { set in
            guard let timestamp = set.timestamp else { return false }
            return timestamp >= todayStart
        }
    }
    
    var body: some View {
        VStack {
            Picker("Category", selection: $selectedCategory) {
                Text("All").tag(ExerciseCategory?.none)
                ForEach(availableCategories, id: \.self) { category in
                    Text(category.id).tag(ExerciseCategory?.some(category))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List {
                if filteredExercises.isEmpty {
                    Text("No exercises in this category.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredExercises, id: \.self) { exercise in
                        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                            HStack {
                                Image(systemName: hasSetToday(for: exercise) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(hasSetToday(for: exercise) ? .green : .gray)
                                Text(exercise.name ?? "Unnamed Exercise")
                            }
                        }
                    }
                    .onDelete(perform: removeExercisesFromWorkout)
                }
            }
        }
        .navigationTitle(workout.name ?? "Workout")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddExercise = true }) {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(workout: workout)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private func removeExercisesFromWorkout(at offsets: IndexSet) {
        offsets.map { filteredExercises[$0] }.forEach { exercise in
            workout.removeFromExercises(exercise)
        }
        do {
            try viewContext.save()
        } catch {
            print("Error removing exercise from workout: \(error.localizedDescription)")
        }
    }
}

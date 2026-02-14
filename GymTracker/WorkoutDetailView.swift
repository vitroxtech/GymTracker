import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var workout: Workout

    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var showingAddExercise = false
    
    // Rename state
    @State private var showingRenameAlert = false
    @State private var exerciseToRename: Exercise?
    @State private var newExerciseName = ""

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
                        .contextMenu {
                            Button {
                                exerciseToRename = exercise
                                newExerciseName = exercise.name ?? ""
                                showingRenameAlert = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                if let index = filteredExercises.firstIndex(of: exercise) {
                                    removeExercisesFromWorkout(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
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
        .alert("Rename Exercise", isPresented: $showingRenameAlert) {
            TextField("Exercise Name", text: $newExerciseName)
            Button("Cancel", role: .cancel) { exerciseToRename = nil }
            Button("Save") {
                renameExercise()
            }
        } message: {
            Text("Enter a new name for this exercise.")
        }
    }

    private func renameExercise() {
        guard let exercise = exerciseToRename else { return }
        let trimmedName = newExerciseName.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            exercise.name = trimmedName
            do {
                try viewContext.save()
            } catch {
                print("Error renaming exercise: \(error.localizedDescription)")
            }
        }
        exerciseToRename = nil
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

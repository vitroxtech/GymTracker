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
        VStack(spacing: 0) {
            if !availableCategories.isEmpty {
                categoryFilterHeader
            }

            exerciseList
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(workout.name ?? "Workout")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddExercise = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
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

    private var categoryFilterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryButton(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                
                ForEach(availableCategories, id: \.self) { category in
                    categoryButton(title: category.id, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding()
        }
    }

    private func categoryButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }

    private var exerciseList: some View {
        ScrollView {
            VStack(spacing: 16) {
                if filteredExercises.isEmpty {
                    emptyStateView
                } else {
                    exercisesView
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No exercises found")
                .font(.headline)
            Text("Add your first exercise to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }

    private var exercisesView: some View {
        ForEach(filteredExercises, id: \.self) { exercise in
            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                exerciseCard(for: exercise)
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                exerciseContextMenu(for: exercise)
            }
        }
    }

    private func exerciseCard(for exercise: Exercise) -> some View {
        GymCard {
            HStack(spacing: 16) {
                Image(systemName: hasSetToday(for: exercise) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(hasSetToday(for: exercise) ? .green : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name ?? "Unnamed Exercise")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(exercise.categoryEnum.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func exerciseContextMenu(for exercise: Exercise) -> some View {
        Group {
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

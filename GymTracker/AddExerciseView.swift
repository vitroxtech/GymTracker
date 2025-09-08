import SwiftUI
import CoreData

struct AddExerciseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var workout: Workout

    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case createNew = "Create New"
        case addFromLibrary = "Add from Library"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .createNew

    // For Create New Exercise
    @State private var name: String = ""
    @State private var category: ExerciseCategory = .legs

    // For multi-selection
    @State private var selectedExercises = Set<Exercise>()

    // Fetch all exercises for Add from Library
    @FetchRequest(
        entity: Exercise.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) private var allExercises: FetchedResults<Exercise>

    var exercisesNotInWorkout: [Exercise] {
        allExercises.filter { !workout.exercisesArray.contains($0) }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if mode == .createNew {
                    Form {
                        Section(header: Text("Exercise Details")) {
                            TextField("Name", text: $name)
                            Picker("Category", selection: $category) {
                                ForEach(ExerciseCategory.allCases) { cat in
                                    Text(cat.id).tag(cat)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }

                        Button("Save Exercise") {
                            saveNewExercise()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } else {
                    List {
                        if exercisesNotInWorkout.isEmpty {
                            Text("No new exercises to add.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(exercisesNotInWorkout, id: \.self) { exercise in
                                MultipleSelectionRow(
                                    exercise: exercise,
                                    isSelected: selectedExercises.contains(exercise)
                                ) {
                                    toggleSelection(for: exercise)
                                }
                            }
                            .onDelete(perform: deleteExercises)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add Selected") {
                                addSelectedExercises()
                            }
                            .disabled(selectedExercises.isEmpty)
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
        }
    }

    private func saveNewExercise() {
        let newExercise = Exercise(context: viewContext)
        newExercise.name = name.trimmingCharacters(in: .whitespaces)
        newExercise.category = category.rawValue

        workout.addToExercises(newExercise)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save exercise: \(error.localizedDescription)")
        }
    }

    private func toggleSelection(for exercise: Exercise) {
        if selectedExercises.contains(exercise) {
            selectedExercises.remove(exercise)
        } else {
            selectedExercises.insert(exercise)
        }
    }

    private func addSelectedExercises() {
        for exercise in selectedExercises {
            workout.addToExercises(exercise)
        }
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to add exercises: \(error.localizedDescription)")
        }
    }
    
    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exerciseToDelete = exercisesNotInWorkout[index]
            viewContext.delete(exerciseToDelete)
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete exercise: \(error.localizedDescription)")
        }
    }
}

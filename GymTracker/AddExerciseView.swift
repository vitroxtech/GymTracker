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

    var uniqueExercisesNotInWorkout: [Exercise] {
        var seenNames = Set<String>()
        var result = [Exercise]()
        let workoutNames = Set(workout.exercisesArray.compactMap { $0.name })
        
        for exercise in allExercises {
            if let name = exercise.name, !seenNames.contains(name), !workoutNames.contains(name) {
                seenNames.insert(name)
                result.append(exercise)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
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
                        if uniqueExercisesNotInWorkout.isEmpty {
                            Text("No new exercises to add.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(uniqueExercisesNotInWorkout, id: \.self) { exercise in
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
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND workout == nil", trimmedName)
        
        let orphans = (try? viewContext.fetch(request)) ?? []
        let newExercise: Exercise
        
        if !orphans.isEmpty {
            newExercise = orphans[0]
            newExercise.category = category.rawValue
            for i in 1..<orphans.count {
                let other = orphans[i]
                if let sets = other.setEntries as? Set<SetEntry> {
                    for set in sets { set.exercise = newExercise }
                }
                viewContext.delete(other)
            }
        } else {
            newExercise = Exercise(context: viewContext)
            newExercise.name = trimmedName
            newExercise.category = category.rawValue
        }
        
        newExercise.workout = workout
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
        for exerciseTemplate in selectedExercises {
            let templateName = exerciseTemplate.name ?? ""
            let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@ AND workout == nil", templateName)
            
            let orphans = (try? viewContext.fetch(request)) ?? []
            let newExercise: Exercise
            
            if !orphans.isEmpty {
                newExercise = orphans[0]
                for i in 1..<orphans.count {
                    let other = orphans[i]
                    if let sets = other.setEntries as? Set<SetEntry> {
                        for set in sets { set.exercise = newExercise }
                    }
                    viewContext.delete(other)
                }
            } else {
                newExercise = Exercise(context: viewContext)
                newExercise.name = templateName
                newExercise.category = exerciseTemplate.category
                newExercise.note = exerciseTemplate.note
            }
            newExercise.workout = workout
            workout.addToExercises(newExercise)
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
            let exerciseName = uniqueExercisesNotInWorkout[index].name ?? ""
            let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@ AND workout == nil", exerciseName)
            if let orphans = try? viewContext.fetch(request) {
                for orphan in orphans {
                    viewContext.delete(orphan)
                }
            }
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete exercise: \(error.localizedDescription)")
        }
    }
}

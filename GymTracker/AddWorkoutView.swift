import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var selectedCategories: Set<String> = []
    @State private var note: String = ""  // New state for note input

    let allCategories = ["Legs", "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Abs"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Info")) {
                    TextField("Workout Name", text: $name)
                }

                Section(header: Text("Exercise Categories")) {
                    ForEach(allCategories, id: \.self) { category in
                        MultipleWorkoutSelectionRow(title: category, isSelected: selectedCategories.contains(category)) {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        }
                    }
                }

                Section(header: Text("Exercise Note")) {  // New note section
                    TextEditor(text: $note)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4))
                        )
                }

                Button("Save Workout") {
                    addWorkout()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategories.isEmpty)
            }
            .navigationTitle("Add Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }

    private func addWorkout() {
        let newWorkout = Workout(context: viewContext)
        newWorkout.name = name.trimmingCharacters(in: .whitespaces)

        // Create exercises for each selected category and apply the note
        for categoryName in selectedCategories {
            let exercise = Exercise(context: viewContext)
            exercise.name = "\(name): \(categoryName)" // Default name based on workout and category
            exercise.category = categoryName
            exercise.note = note.trimmingCharacters(in: .whitespaces)
            exercise.workout = newWorkout
            newWorkout.addToExercises(exercise)
        }

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save workout: \(error.localizedDescription)")
        }
    }
}

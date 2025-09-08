//
//  ExcerciseLibraryView.swift
//  GymTracker
//
//  Created by miguel gomez on 17/5/25.
//

import SwiftUI
import CoreData

struct ExerciseLibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var workout: Workout
    
    // Fetch all exercises sorted by name
    @FetchRequest(
        entity: Exercise.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) private var allExercises: FetchedResults<Exercise>
    
    // Exercises not yet in this workout
    var exercisesNotInWorkout: [Exercise] {
        allExercises.filter { !workout.exercisesArray.contains($0) }
    }
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                if exercisesNotInWorkout.isEmpty {
                    Text("No new exercises to add.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(exercisesNotInWorkout, id: \.self) { exercise in
                        Button(action: {
                            addExerciseToWorkout(exercise)
                        }) {
                            Text(exercise.name ?? "Unnamed Exercise")
                        }
                    }
                }
            }
            .navigationTitle("Exercise Library")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addExerciseToWorkout(_ exercise: Exercise) {
        workout.addToExercises(exercise)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to add exercise: \(error.localizedDescription)")
        }
    }
}

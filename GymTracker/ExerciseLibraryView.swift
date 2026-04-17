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
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                if uniqueExercisesNotInWorkout.isEmpty {
                    Text("No new exercises to add.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(uniqueExercisesNotInWorkout, id: \.self) { exercise in
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

    private func addExerciseToWorkout(_ exerciseTemplate: Exercise) {
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
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to add exercise: \(error.localizedDescription)")
        }
    }
}

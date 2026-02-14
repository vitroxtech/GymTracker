import Foundation
import CoreData

class CSVManager {
    static let shared = CSVManager()
    private init() {}

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    func exportToCSV(context: NSManagedObjectContext) -> String {
        let workoutFetch: NSFetchRequest<Workout> = Workout.fetchRequest()
        workoutFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.name, ascending: true)]
        
        do {
            let workouts = try context.fetch(workoutFetch)
            var csvString = "WorkoutName,ExerciseName,ExerciseCategory,ExerciseNote,SetWeight,SetReps,SetTimestamp,SessionStartTime,SessionEndTime\n"
            
            for workout in workouts {
                let workoutName = workout.name ?? "Unknown Workout"
                let exercises = (workout.exercises as? Set<Exercise>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
                
                if exercises.isEmpty {
                    // Export workout even without exercises
                    csvString.append("\"\(workoutName)\",\"\",\"\",\"\",,,,\"\",\"\"\n")
                    continue
                }
                
                for exercise in exercises {
                    let exerciseName = exercise.name ?? "Unknown Exercise"
                    let exerciseCategory = exercise.category ?? "None"
                    let exerciseNote = exercise.note ?? ""
                    let sets = (exercise.setEntries as? Set<SetEntry>)?.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) } ?? []
                    
                    if sets.isEmpty {
                        // Export exercise even without sets
                        csvString.append("\"\(workoutName)\",\"\(exerciseName)\",\"\(exerciseCategory)\",\"\(exerciseNote)\",,,,\"\",\"\"\n")
                        continue
                    }
                    
                    for entry in sets {
                        let weight = entry.weight
                        let reps = entry.reps
                        let timestamp = entry.timestamp != nil ? dateFormatter.string(from: entry.timestamp!) : ""
                        let sessionStart = entry.session?.startTime != nil ? dateFormatter.string(from: entry.session!.startTime!) : ""
                        let sessionEnd = entry.session?.endTime != nil ? dateFormatter.string(from: entry.session!.endTime!) : ""
                        
                        let row = "\"\(workoutName)\",\"\(exerciseName)\",\"\(exerciseCategory)\",\"\(exerciseNote)\",\(weight),\(reps),\"\(timestamp)\",\"\(sessionStart)\",\"\(sessionEnd)\"\n"
                        csvString.append(row)
                    }
                }
            }
            
            return csvString
        } catch {
            print("Failed to fetch data for export: \(error)")
            return ""
        }
    }

    func importFromCSV(_ csvString: String, context: NSManagedObjectContext) {
        // Step 1: Replace data - Delete all existing workouts (and cascade)
        deleteAllData(context: context)
        
        let rows = csvString.components(separatedBy: "\n")
        guard rows.count > 1 else { return }
        
        // Skip header
        let dataRows = rows.dropFirst()
        
        // Track created objects for this import session to avoid duplicates within the CSV parsing
        var createdWorkouts: [String: Workout] = [:]
        var createdExercises: [String: Exercise] = [:] // Key: "workoutName|exerciseName"
        var createdSessions: [String: Session] = [:] // Key: "workoutName|sessionStart"

        for row in dataRows {
            if row.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            
            let columns = parseCSVRow(row)
            if columns.count < 9 { continue }
            
            let workoutName = columns[0].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if workoutName.isEmpty { continue }

            let exerciseName = columns[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let exerciseCategory = columns[2].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let exerciseNote = columns[3].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            
            let weightStr = columns[4]
            let repsStr = columns[5]
            let weight = weightStr.isEmpty ? nil : Double(weightStr)
            let reps = repsStr.isEmpty ? nil : Int16(repsStr)
            
            let timestamp = dateFormatter.date(from: columns[6].trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
            let sessionStartStr = columns[7].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let sessionStart = dateFormatter.date(from: sessionStartStr)
            let sessionEndStr = columns[8].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let sessionEnd = dateFormatter.date(from: sessionEndStr)
            
            // 1. Get or Create Workout
            let workout: Workout
            if let existing = createdWorkouts[workoutName] {
                workout = existing
            } else {
                workout = Workout(context: context)
                workout.name = workoutName
                createdWorkouts[workoutName] = workout
            }
            
            // 2. Get or Create Exercise if name exists
            if !exerciseName.isEmpty {
                let exerciseKey = "\(workoutName)|\(exerciseName)"
                let exercise: Exercise
                if let existing = createdExercises[exerciseKey] {
                    exercise = existing
                    // Update note if it was empty before or changed (though in replacement mode it's fresh)
                    exercise.note = exerciseNote
                } else {
                    exercise = Exercise(context: context)
                    exercise.name = exerciseName
                    exercise.category = exerciseCategory
                    exercise.note = exerciseNote
                    exercise.workout = workout
                    workout.addToExercises(exercise)
                    createdExercises[exerciseKey] = exercise
                }
                
                // 3. Create Session and SetEntry if weight/reps exist
                if let w = weight, let r = reps {
                    let session: Session
                    let sessionKey = "\(workoutName)|\(sessionStartStr)"
                    
                    if !sessionStartStr.isEmpty, let existing = createdSessions[sessionKey] {
                        session = existing
                    } else {
                        session = Session(context: context)
                        session.startTime = sessionStart
                        session.endTime = sessionEnd
                        session.workout = workout
                        session.duration = sessionEnd?.timeIntervalSince(sessionStart ?? Date()) ?? 0
                        workout.addToSessions(session)
                        if !sessionStartStr.isEmpty {
                            createdSessions[sessionKey] = session
                        }
                    }
                    
                    let setEntry = SetEntry(context: context)
                    setEntry.weight = w
                    setEntry.reps = r
                    setEntry.timestamp = timestamp
                    setEntry.exercise = exercise
                    setEntry.session = session
                    
                    exercise.addToSetEntries(setEntry)
                    session.addToSetEntries(setEntry)
                    
                    // Increment volume
                    session.totalVolume += Double(r) * w
                }
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save imported data: \(error)")
        }
    }
    
    private func deleteAllData(context: NSManagedObjectContext) {
        let workoutFetch: NSFetchRequest<NSFetchRequestResult> = Workout.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: workoutFetch)
        
        // Batch delete doesn't sync with context automatically, so we'll just fetch and delete individually for simplicity/safety in this small app
        let fetchAll: NSFetchRequest<Workout> = Workout.fetchRequest()
        if let workouts = try? context.fetch(fetchAll) {
            for w in workouts {
                context.delete(w)
            }
        }
        
        // Also ensure orphans are gone if any (though cascade should handle it)
        let sessionFetch: NSFetchRequest<Session> = Session.fetchRequest()
        if let sessions = try? context.fetch(sessionFetch) {
            for s in sessions {
                context.delete(s)
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error clearing data: \(error)")
        }
    }
    
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentToken = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentToken)
                currentToken = ""
            } else {
                currentToken.append(char)
            }
        }
        result.append(currentToken)
        return result
    }
}

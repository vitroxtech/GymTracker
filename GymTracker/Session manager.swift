import Foundation
import CoreData

class SessionManager: ObservableObject {
    static let shared = SessionManager()

    var activeSessions: [Workout: Session] = [:]

    private init() {}

    func startSession(for workout: Workout, context: NSManagedObjectContext) -> Session {
        if let existingSession = activeSessions[workout] {
            return existingSession
        }

        let session = Session(context: context)
        session.startTime = Date()
        session.totalVolume = 0
        session.workout = workout

        workout.addToSessions(session)
        activeSessions[workout] = session

        return session
    }

    func endSession(for workout: Workout, context: NSManagedObjectContext) {
        guard let session = activeSessions[workout] else { return }

        session.endTime = Date()
        session.duration = session.endTime?.timeIntervalSince(session.startTime ?? Date()) ?? 0
        activeSessions.removeValue(forKey: workout)

        do {
            try context.save()
        } catch {
            print("Error saving session end: \(error)")
        }
    }

    func addSetEntry(
        to exercise: Exercise,
        reps: Int16,
        weight: Double,
        context: NSManagedObjectContext
    ) {
        guard let workout = exercise.workout else {
            print("Exercise has no associated workout.")
            return
        }

        let session = startSession(for: workout, context: context)

        let setEntry = SetEntry(context: context)
        setEntry.reps = reps
        setEntry.weight = weight
        setEntry.timestamp = Date()
        setEntry.exercise = exercise
        setEntry.session = session

        exercise.addToSetEntries(setEntry)
        session.addToSetEntries(setEntry)

        // Update session total volume
        session.totalVolume += Double(reps) * weight

        do {
            try context.save()
        } catch {
            print("Failed to save SetEntry: \(error.localizedDescription)")
        }
    }

    func removeSetEntry(_ setEntry: SetEntry, context: NSManagedObjectContext) {
        guard let session = setEntry.session else { return }

        // Deduct volume
        let volume = Double(setEntry.reps) * setEntry.weight
        session.totalVolume -= volume

        context.delete(setEntry)

        do {
            try context.save()
        } catch {
            print("Failed to remove SetEntry: \(error.localizedDescription)")
        }
    }
}

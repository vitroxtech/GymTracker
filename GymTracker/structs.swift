import Foundation

struct WorkoutData: Codable {
    var name: String?
    var exercises: [ExerciseData]
    var sessions: [SessionData]
}

struct ExerciseData: Codable {
    var name: String?
    var category: String?
    var date: Date?
    var setEntries: [SetEntryData]
}

struct SetEntryData: Codable {
    var weight: Double
    var reps: Int
    var timestamp: Date
}

struct SessionData: Codable {
    var startTime: Date?
    var endTime: Date?
    var duration: Double
    var totalVolume: Double
    var date: Date?
    var setEntries: [SetEntryData]
}



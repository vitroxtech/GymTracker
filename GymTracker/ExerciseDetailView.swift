import SwiftUI
import Charts
import UserNotifications
import CoreData

struct ExerciseDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var exercise: Exercise

    @StateObject private var cooldownManager = RestCooldownManager.shared

    @State private var weightPickerValue: Int = 1
    @State private var repsPickerValue: Int = 1
    @State private var sessionFinished = false
    @State private var currentSession: Session?
    
    @State private var noteText: String = ""

    var groupedSets: [(date: Date, sets: [SetEntry])] {
        let calendar = Calendar.current
        let groupedDict = Dictionary(grouping: (exercise.setEntries as? Set<SetEntry> ?? [])) {
            calendar.startOfDay(for: $0.timestamp ?? Date())
        }
        return groupedDict
            .map { ($0.key, $0.value.sorted { ($1.timestamp ?? Date()) > ($0.timestamp ?? Date()) }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        Form {
            if cooldownManager.isActive {
                Section {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Rest Time")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {
                                cooldownManager.cancelCooldown()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            }

                            ProgressView(value: Double(120 - cooldownManager.remaining), total: 120)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        }
                        .foregroundColor(.red)
                    }
                }
            }

            if !groupedSets.isEmpty {
                Section(header: Text("Volume Over Time").foregroundColor(.blue)) {
                    Chart {
                        ForEach(groupedSets, id: \.date) { (date, sets) in
                            LineMark(
                                x: .value("Date", date),
                                y: .value("Volume", volume(for: sets))
                            )
                            .foregroundStyle(.green)
                            .symbol(Circle())
                        }
                    }
                    .frame(height: 150)
                }
            }

            Section(header: Text("Exercise Note")) {
                TextEditor(text: $noteText)
                    .frame(minHeight: 25)
                    .padding(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4))
                    )
                    .onChange(of: noteText) { newValue in
                        exercise.note = newValue
                        do {
                            try viewContext.save()
                        } catch {
                            print("Failed to autosave note: \(error.localizedDescription)")
                        }
                    }
            }

            Section(header: Text("Add Set")) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Weight (kg)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Picker("", selection: $weightPickerValue) {
                            ForEach(1...200, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: 100, maxHeight: 100)
                        .clipped()
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Reps")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Picker("", selection: $repsPickerValue) {
                            ForEach(1...200, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: 100, maxHeight: 100)
                        .clipped()
                    }
                }

                Button("Add Set") {
                    addSet()
                }
            }

            ForEach(groupedSets.reversed(), id: \.date) { (date, sets) in
                Section(header: Text("\(formattedDate(date)) — Volume: \(volume(for: sets), specifier: "%.0f") kg").foregroundColor(.red)) {
                    ForEach(sets.reversed(), id: \.self) { set in
                        HStack {
                            Text("\(set.weight, specifier: "%.1f") kg x \(set.reps) reps")
                            Spacer()
                            Text(formattedTime(set.timestamp))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                deleteSet(set)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name ?? "Exercise")
        .onAppear {
            requestNotificationPermission()
            loadCurrentSession()
            cooldownManager.resumeIfNeeded()

            if let lastSet = getLastSet() {
                weightPickerValue = max(1, Int(lastSet.weight.rounded()))
                repsPickerValue = max(1, Int(lastSet.reps))
            }

            noteText = exercise.note ?? ""
        }
    }

    // MARK: - Actions

    private func addSet() {
        guard let workout = exercise.workout else { return }

        let newSet = SetEntry(context: viewContext)
        newSet.weight = Double(weightPickerValue)
        newSet.reps = Int16(repsPickerValue)
        newSet.timestamp = Date()
        newSet.exercise = exercise

        let session = SessionManager.shared.startSession(for: workout, context: viewContext)
        session.totalVolume += newSet.weight * Double(newSet.reps)
        session.endTime = nil

        currentSession = session

        do {
            try viewContext.save()
            cooldownManager.startCooldown()
        } catch {
            print("Failed to save set: \(error.localizedDescription)")
        }
    }

    private func deleteSet(_ set: SetEntry) {
        if let session = currentSession {
            let volumeToRemove = set.weight * Double(set.reps)
            session.totalVolume = max(0, session.totalVolume - volumeToRemove)
        }

        viewContext.delete(set)

        do {
            try viewContext.save()
        } catch {
            print("Error deleting set: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func getLastSet() -> SetEntry? {
        return (exercise.setEntries as? Set<SetEntry>)?
            .sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
            .first
    }

    private func loadCurrentSession() {
        guard let workout = exercise.workout else {
            currentSession = nil
            return
        }
        currentSession = SessionManager.shared.activeSessions[workout]
    }

    private func volume(for sets: [SetEntry]) -> Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if !granted {
                print("User denied notifications.")
            }
        }
    }
}

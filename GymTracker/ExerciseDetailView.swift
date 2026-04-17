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
        ScrollView {
            VStack(spacing: 20) {
                if cooldownManager.isActive {
                    GymCard {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("RESTING")
                                        .font(.caption2.bold())
                                        .foregroundColor(.blue)
                                        .tracking(2)
                                    
                                    Text(cooldownManager.remaining > 30 ? "Stay focused!" : "Get ready!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: { cooldownManager.cancelCooldown() }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.title3)
                                }
                            }
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(cooldownManager.remaining / 60):\(String(format: "%02d", cooldownManager.remaining % 60))")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                    .contentTransition(.numericText())
                                
                                Text("min")
                                    .font(.title3.bold())
                                    .foregroundColor(.secondary)
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: max(0, geo.size.width * CGFloat(1 - Double(cooldownManager.remaining) / cooldownManager.totalDuration)), height: 8)
                                        .animation(.linear(duration: 1), value: cooldownManager.remaining)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !groupedSets.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Progress").sectionHeaderStyle()
                        GymCard {
                            Chart {
                                ForEach(groupedSets, id: \.date) { (date, sets) in
                                    AreaMark(
                                        x: .value("Date", date),
                                        y: .value("Volume", volume(for: sets))
                                    )
                                    .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .blue.opacity(0)], startPoint: .top, endPoint: .bottom))
                                    
                                    LineMark(
                                        x: .value("Date", date),
                                        y: .value("Volume", volume(for: sets))
                                    )
                                    .foregroundStyle(.blue)
                                    .symbol {
                                        Circle()
                                            .strokeBorder(.blue, lineWidth: 2)
                                            .background(Circle().fill(.background))
                                            .frame(width: 10, height: 10)
                                    }
                                }
                            }
                            .frame(height: 160)
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Set").sectionHeaderStyle()
                    GymCard {
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                // Weight Input
                                VStack(spacing: 8) {
                                    Text("KG")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("0", value: $weightPickerValue, formatter: NumberFormatter())
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 80, height: 50)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                    
                                    HStack {
                                        Button("-1") { weightPickerValue = max(0, weightPickerValue - 1) }
                                        Button("+1") { weightPickerValue += 1 }
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                }
                                
                                Divider().frame(height: 60)
                                
                                // Reps Input
                                VStack(spacing: 8) {
                                    Text("REPS")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("0", value: $repsPickerValue, formatter: NumberFormatter())
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 80, height: 50)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                    
                                    HStack {
                                        Button("-1") { repsPickerValue = max(0, repsPickerValue - 1) }
                                        Button("+1") { repsPickerValue += 1 }
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                }
                            }
                            
                            PrimaryButton("Log Set", icon: "plus") {
                                addSet()
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Rest Time").sectionHeaderStyle()
                    GymCard {
                        HStack {
                            Text("Duration")
                                .fontWeight(.semibold)
                            Spacer()
                            
                            let currentRestTime: Int16 = exercise.restTime == 0 ? 120 : exercise.restTime
                            Stepper(value: Binding(
                                get: { Int(currentRestTime) },
                                set: { 
                                    exercise.restTime = Int16($0)
                                    try? viewContext.save()
                                }
                            ), in: 0...900, step: 15) {
                                Text("\(currentRestTime) seconds")
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes").sectionHeaderStyle()
                    GymCard {
                        TextEditor(text: $noteText)
                            .frame(minHeight: 60)
                            .onChange(of: noteText) { newValue in
                                exercise.note = newValue
                                try? viewContext.save()
                            }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("History").sectionHeaderStyle()
                    ForEach(groupedSets.reversed(), id: \.date) { (date, sets) in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(formattedDate(date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(volume(for: sets), specifier: "%.0f") kg volume")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 1) {
                                ForEach(sets.reversed(), id: \.self) { set in
                                    HStack {
                                        Text("\(set.weight, specifier: "%.1f") kg")
                                            .fontWeight(.semibold)
                                        Text("x")
                                            .foregroundColor(.secondary)
                                        Text("\(set.reps) reps")
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Text(formattedTime(set.timestamp))
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .contextMenu {
                                        Button("Delete", role: .destructive) {
                                            deleteSet(set)
                                        }
                                    }
                                }
                            }
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
            
            if currentSession != nil {
                VStack {
                    Divider()
                    Button(action: { finishWorkout() }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Finish Workout Session")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding()
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
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
            let cooldownDuration = exercise.restTime == 0 ? 120 : TimeInterval(exercise.restTime)
            cooldownManager.startCooldown(duration: cooldownDuration)
        } catch {
            print("Failed to save set: \(error.localizedDescription)")
        }
    }

    private func finishWorkout() {
        guard let workout = exercise.workout else { return }
        SessionManager.shared.finishActiveSession(for: workout, context: viewContext)
        currentSession = nil
        sessionFinished = true
        // Maybe dismiss or show a success state? For now just clear currentSession
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
        
        if let session = SessionManager.shared.activeSessions[workout] {
            currentSession = session
            return
        }
        
        // If not in memory, check for unfinished sessions in Core Data
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        request.predicate = NSPredicate(format: "workout == %@ AND endTime == nil", workout)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Session.startTime, ascending: false)]
        request.fetchLimit = 1
        
        do {
            currentSession = try viewContext.fetch(request).first
            if let session = currentSession {
                // Sync back to SessionManager cache
                SessionManager.shared.activeSessions[workout] = session
            }
        } catch {
            print("Error recovering session in ExerciseDetailView: \(error)")
        }
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

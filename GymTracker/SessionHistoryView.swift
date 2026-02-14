import SwiftUI
import CoreData

struct SessionHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch sessions sorted by startTime descending
    @FetchRequest(
        entity: Session.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.startTime, ascending: false)]
    ) private var sessions: FetchedResults<Session>

    var body: some View {
        List {
            ForEach(sessions, id: \.self) { session in
                HStack {
                    VStack(alignment: .leading) {
                        Text(session.workout?.name ?? "Unnamed Workout")
                                                    .font(.headline)
                        Text(formattedDateOnly(session.startTime))
                        // Show duration (if ended)
                        if let endTime = session.endTime {
                            Text(durationString(from: session.startTime, to: endTime))
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        } else {
                            Text("Ongoing")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }

                        // Show volume in red
                        Text("Total volume: \(session.totalVolume, specifier: "%.0f")")
                            .foregroundColor(.red)
                    }

                    Spacer()

                    // End session button
                    if session.endTime == nil {
                        Button("X") {
                            finishSession(session)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 6)
            }
            .onDelete(perform: deleteSessions)
        }
        .navigationTitle("Gym home")
    }

    private func finishSession(_ session: Session) {
        session.endTime = Date()
        do {
            try viewContext.save()
        } catch {
            print("Failed to finish session: \(error.localizedDescription)")
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            viewContext.delete(session)
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete session: \(error.localizedDescription)")
        }
    }

    private func formattedDateOnly(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func durationString(from start: Date?, to end: Date) -> String {
        guard let start = start else { return "N/A" }

        let duration = Int(end.timeIntervalSince(start))
        let minutes = (duration / 60) % 60
        let hours = duration / 3600

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

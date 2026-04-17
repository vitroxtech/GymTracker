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
            Section(header: Text("Past Sessions").sectionHeaderStyle()) {
                ForEach(sessions, id: \.self) { session in
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.workout?.name ?? "Unnamed Workout")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "calendar")
                                Text(formattedDateOnly(session.startTime))
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            if let endTime = session.endTime {
                                HStack {
                                    Image(systemName: "clock")
                                    Text(durationString(from: session.startTime, to: endTime))
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            } else {
                                Text("Ongoing")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(session.totalVolume, specifier: "%.0f")")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("kg total")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if session.endTime == nil {
                                Button(action: { finishSession(session) }) {
                                    Text("Finish")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.green)
                                        .clipShape(Capsule())
                                        .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteSessions)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("History")
    }

    private func finishSession(_ session: Session) {
        if let workout = session.workout {
            SessionManager.shared.finishActiveSession(for: workout, context: viewContext)
        } else {
            session.endTime = Date()
            do {
                try viewContext.save()
            } catch {
                print("Failed to finish session: \(error.localizedDescription)")
            }
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

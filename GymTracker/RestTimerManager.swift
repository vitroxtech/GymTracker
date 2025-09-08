import SwiftUI
import ActivityKit

// MARK: - Activity Attributes
struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startDate: Date
        var duration: TimeInterval
    }
}

@MainActor
class RestTimerManager: ObservableObject {
    private var activity: Activity<RestTimerAttributes>?
    private var timer: Timer?

    @Published var isRunning = false
    @Published var remainingSeconds: Int = 120
    private var startDate: Date?
    private var totalDuration: TimeInterval = 120

    func startTimer(duration: TimeInterval = 120) {
        guard !isRunning else { return }

        isRunning = true
        remainingSeconds = Int(duration)
        totalDuration = duration
        startDate = Date()

        Task {
            await startLiveActivity()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.remainingSeconds -= 1

                if self.remainingSeconds <= 0 {
                    self.stopTimer()
                }
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false

        Task {
            await endLiveActivity()
        }

        remainingSeconds = Int(totalDuration)
        startDate = nil
    }

    // MARK: - Live Activity Methods

    private func startLiveActivity() async {
        guard let startDate = startDate else { return }

        let attributes = RestTimerAttributes()
        let contentState = RestTimerAttributes.ContentState(
            startDate: startDate,
            duration: totalDuration
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: contentState, staleDate: startDate.addingTimeInterval(totalDuration + 30))
            )
            print("✅ Live Activity started")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    private func endLiveActivity() async {
        guard let activity = activity,
              let startDate = startDate else { return }

        let contentState = RestTimerAttributes.ContentState(
            startDate: startDate,
            duration: totalDuration
        )

        do {
            try await activity.end(
                ActivityContent(state: contentState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            print("✅ Live Activity ended")
        } catch {
            print("❌ Failed to end Live Activity: \(error)")
        }

        self.activity = nil
    }

    // MARK: - UI Helpers

    func timeString() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var progressPercentage: Double {
        return Double(totalDuration - Double(remainingSeconds)) / totalDuration
    }
}

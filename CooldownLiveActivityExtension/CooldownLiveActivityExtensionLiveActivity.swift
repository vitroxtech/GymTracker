import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Activity Attributes
struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startDate: Date
        var duration: TimeInterval
    }
}

// MARK: - Live Activity Widget
struct CooldownLiveActivityExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // Lock screen / banner UI - Compact with ring and timer
            let start = context.state.startDate
            let end = start.addingTimeInterval(context.state.duration)
            let progress = min(Date().timeIntervalSince(start) / context.state.duration, 1.0)

            HStack(spacing: 12) {
                // Ring progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 30, height: 30)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                }

                Text("Rest Timer")
                    .font(.headline)

                Spacer()

                // Countdown timer
                Text(timerInterval: start...end, countsDown: true)
                    .font(.title2)
                    .monospacedDigit()
            }
            .padding(.horizontal)
            .frame(height: 50)
        } dynamicIsland: { context in
            let start = context.state.startDate
            let end = start.addingTimeInterval(context.state.duration)
            let progress = min(Date().timeIntervalSince(start) / context.state.duration, 1.0)

            return DynamicIsland {
                    // Expanded region - keep this simple to avoid large UI
                    DynamicIslandExpandedRegion(.center) {
                        HStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                    .frame(width: 24, height: 24)

                                Circle()
                                    .trim(from: 0, to: CGFloat(progress))
                                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 24, height: 24)
                                    .rotationEffect(.degrees(-90))
                            }

                            Text(timerInterval: start...end, countsDown: true)
                                .font(.headline)
                                .monospacedDigit()
                        }
                        .padding(.horizontal)
                    }
                } compactLeading: {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                            .frame(width: 20, height: 20)

                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-90))
                    }
                } compactTrailing: {
                    Text(timerInterval: start...end, countsDown: true)
                        .font(.caption2)
                        .monospacedDigit()
                } minimal: {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 16, height: 16)

                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 16, height: 16)
                            .rotationEffect(.degrees(-90))
                    }
                }
        }
    }
}

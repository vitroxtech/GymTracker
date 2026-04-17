//
//  Untitled.swift
//   
//
//  Created by miguel gomez on 7/6/25.
//
import Foundation
import ActivityKit
import UserNotifications
import Combine

final class RestCooldownManager: ObservableObject {
    static let shared = RestCooldownManager()

    private var activity: Activity<RestTimerAttributes>?
    private var timer: Timer?
    @Published var remaining: Int = 0
    @Published var totalDuration: TimeInterval = 120
    private var cooldownEnd: Date?
    private init() {}

    func startCooldown(duration: TimeInterval = 120) {
        self.totalDuration = duration > 0 ? duration : 120
        let start = Date()
        let end = start.addingTimeInterval(self.totalDuration)
        cooldownEnd = end

        // Start Live Activity
        let attributes = RestTimerAttributes()
        let content = RestTimerAttributes.ContentState(startDate: start, duration: self.totalDuration)

        do {
            activity = try Activity<RestTimerAttributes>.request(attributes: attributes, contentState: content)
            print("Started Live Activity: \(String(describing: activity?.id))")
        } catch {
            print("Live Activity error: \(error)")
        }

        // Schedule Local Notification
        let contentNotif = UNMutableNotificationContent()
        contentNotif.title = "Rest Time Over"
        contentNotif.body = "Your \(Int(self.totalDuration)) seconds rest is complete"
        contentNotif.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: self.totalDuration, repeats: false)
        let request = UNNotificationRequest(identifier: "rest_done", content: contentNotif, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            } else {
                print("Scheduled cooldown notification")
            }
        }

        // Start Timer
        startCountdown(to: end)
    }

    private func startCountdown(to endDate: Date) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let remainingSeconds = Int(ceil(endDate.timeIntervalSinceNow))
            self.remaining = max(0, remainingSeconds)
            if endDate.timeIntervalSinceNow <= 0 {
                self.cancelCooldown(fromTimer: true)
            }
        }
    }

    func cancelCooldown(fromTimer: Bool = false) {
        cooldownEnd = nil
        timer?.invalidate()
        timer = nil
        remaining = 0
        
        if !fromTimer {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest_done"])
        }

        Task {
            await activity?.end(dismissalPolicy: .immediate)
            activity = nil
        }

        print("Cooldown cancelled")
    }

    func resumeIfNeeded() {
        guard let end = cooldownEnd, Date() < end else {
            cooldownEnd = nil
            remaining = 0
            return
        }
        startCountdown(to: end)
        print("Resumed cooldown with \(Int(end.timeIntervalSinceNow)) seconds remaining")
    }

    var isActive: Bool {
        return remaining > 0
    }
}

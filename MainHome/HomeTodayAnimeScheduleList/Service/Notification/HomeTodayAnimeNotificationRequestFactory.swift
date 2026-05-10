//
//  HomeTodayAnimeNotificationRequestFactory.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import Foundation
import UserNotifications

struct HomeTodayAnimeNotificationRequestFactory {
    private var calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func makeRequest(for reminder: HomeTodayAnimeBroadcastReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "動畫即將播出"
        content.body = "\(reminder.title) 將在 1 小時後播出。"
        content.sound = .default
        content.userInfo = [
            "route": "todayAnimeSchedule",
            "day": reminder.day.rawValue,
            "animeID": reminder.animeID
        ]

        var localCalendar = calendar
        localCalendar.timeZone = .autoupdatingCurrent
        var dateComponents = localCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminder.notificationDate
        )
        dateComponents.calendar = localCalendar
        dateComponents.timeZone = localCalendar.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        return UNNotificationRequest(
            identifier: identifier(for: reminder),
            content: content,
            trigger: trigger
        )
    }

    private func identifier(for reminder: HomeTodayAnimeBroadcastReminder) -> String {
        let timestamp = Int(reminder.notificationDate.timeIntervalSince1970)
        return "\(HomeTodayAnimeNotificationConfig.reminderIdentifierPrefix)\(reminder.animeID).\(timestamp)"
    }
}

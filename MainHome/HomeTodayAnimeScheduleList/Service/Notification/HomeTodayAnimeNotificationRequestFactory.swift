//
//  HomeTodayAnimeNotificationRequestFactory.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import Foundation
import UserNotifications

struct HomeTodayAnimeNotificationRequestFactory {
    private enum NotificationRoute: String {
        case todayAnimeSchedule
    }

    private enum UserInfoKey {
        static let route = "route"
        static let day = "day"
        static let animeID = "animeID"
    }

    private var calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func makeRequest(for reminder: HomeTodayAnimeBroadcastReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "動畫開始播出"
        content.body = "\(reminder.title) 現在開始播出。"
        content.sound = .default
        content.userInfo = userInfo(for: reminder)

        return UNNotificationRequest(
            identifier: identifier(for: reminder),
            content: content,
            trigger: trigger(for: reminder)
        )
    }

    private func identifier(for reminder: HomeTodayAnimeBroadcastReminder) -> String {
        let timestamp = Int(reminder.scheduledDate.timeIntervalSince1970)
        return "\(HomeTodayAnimeNotificationConfig.reminderIdentifierPrefix)\(reminder.animeID).\(timestamp)"
    }

    private func userInfo(for reminder: HomeTodayAnimeBroadcastReminder) -> [AnyHashable: Any] {
        [
            UserInfoKey.route: NotificationRoute.todayAnimeSchedule.rawValue,
            UserInfoKey.day: reminder.day.rawValue,
            UserInfoKey.animeID: reminder.animeID
        ]
    }

    private func trigger(for reminder: HomeTodayAnimeBroadcastReminder) -> UNCalendarNotificationTrigger {
        var localCalendar = calendar
        localCalendar.timeZone = .autoupdatingCurrent

        var dateComponents = localCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminder.scheduledDate
        )
        dateComponents.calendar = localCalendar
        dateComponents.timeZone = localCalendar.timeZone

        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    }
}

//
//  HomeTodayAnimeNotificationConfig.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import Foundation

enum HomeTodayAnimeNotificationConfig {
    static let enabledKey = "homeTodayAnimeDailyNotificationEnabled"
    static let legacySummaryIdentifierPrefix = "home.todayAnime.dailySummary."
    static let reminderIdentifierPrefix = "home.todayAnime.broadcastReminder."
    static let reminderLeadTime: TimeInterval = 60 * 60
    static let reminderLeadTimeText = "播出前 1 小時"
    static let pageSize = 25
    static let maxPagesPerDay = 4
    static let maxScheduledNotifications = 60
}

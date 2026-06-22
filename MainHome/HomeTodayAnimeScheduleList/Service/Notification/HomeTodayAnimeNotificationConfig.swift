//
//  HomeTodayAnimeNotificationConfig.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import Foundation

// MARK: - HomeTodayAnimeNotificationConfig

enum HomeTodayAnimeNotificationConfig {
    static let enabledKey = "homeTodayAnimeDailyNotificationEnabled"
    static let lastRefreshDateKey = "homeTodayAnimeNotificationLastRefreshDate"
    static let lastRefreshAttemptDateKey = "homeTodayAnimeNotificationLastRefreshAttemptDate"
    static let reconciliationCheckDatesKey = "homeTodayAnimeReminderReconciliationCheckDates"
    static let legacySummaryIdentifierPrefix = "home.todayAnime.dailySummary."
    static let reminderIdentifierPrefix = "home.todayAnime.broadcastReminder."

    static func broadcastReminderIdentifierPrefix(forAnimeID animeID: Int) -> String {
        "\(reminderIdentifierPrefix)\(animeID)."
    }
    static let pageSize = 25
    static let maxPagesPerDay = 4
    static let maxScheduledNotifications = 60
    static let scheduleRefreshInterval: TimeInterval = 6 * 60 * 60
    static let failedScheduleRefreshRetryInterval: TimeInterval = 30 * 60
    static let reconciliationCheckInterval: TimeInterval = 24 * 60 * 60
    static let minimumHealthyPendingNotificationCount = 12
}

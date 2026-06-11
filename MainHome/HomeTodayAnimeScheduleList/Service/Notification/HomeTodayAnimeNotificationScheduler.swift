//
//  HomeTodayAnimeNotificationScheduler.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import Combine
import Foundation
import OSLog
import UserNotifications

@MainActor
final class HomeTodayAnimeNotificationScheduler: BaseUserNotificationManager {
    private let reminderFactory: HomeTodayAnimeBroadcastReminderFactory
    private let requestFactory: HomeTodayAnimeNotificationRequestFactory
    private let subscriptionProvider: () -> [AnimeBroadcastReminderSnapshot]

    private var lastRefreshDate: Date? {
        userDefaults.object(forKey: HomeTodayAnimeNotificationConfig.lastRefreshDateKey) as? Date
    }

    private var lastRefreshAttemptDate: Date? {
        userDefaults.object(forKey: HomeTodayAnimeNotificationConfig.lastRefreshAttemptDateKey) as? Date
    }

    init(
        subscriptionProvider: @escaping @MainActor () -> [AnimeBroadcastReminderSnapshot] = { [] },
        notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current(),
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.subscriptionProvider = subscriptionProvider
        self.reminderFactory = HomeTodayAnimeBroadcastReminderFactory()
        self.requestFactory = HomeTodayAnimeNotificationRequestFactory(calendar: calendar)
        super.init(
            enabledKey: HomeTodayAnimeNotificationConfig.enabledKey,
            managedIdentifierPrefixes: [
                HomeTodayAnimeNotificationConfig.legacySummaryIdentifierPrefix,
                HomeTodayAnimeNotificationConfig.reminderIdentifierPrefix
            ],
            notificationCenter: notificationCenter,
            userDefaults: userDefaults
        )
    }

    func refreshAuthorizationStatus() async {
        guard await refreshAuthorizationState() == .denied else { return }
        guard state == .enabled || state == .processing(.refreshing) else { return }

        await removeManagedPendingNotificationRequests()
        setState(.disabled)
        clearLastRefreshDate()
    }

    func clearNotificationsForOpenedResponse(_ response: UNNotificationResponse) async {
        let identifier = response.notification.request.identifier
        guard isManagedNotificationIdentifier(identifier) else { return }

        if let animeID = response.notification.request.content.userInfo["animeID"] as? Int {
            let prefix = HomeTodayAnimeNotificationConfig.broadcastReminderIdentifierPrefix(forAnimeID: animeID)
            _ = await removeManagedNotifications { $0.hasPrefix(prefix) }
        } else {
            _ = await removeManagedNotifications { $0 == identifier }
        }
    }

    func refreshScheduledNotificationIfNeeded() async {
        _ = await refreshAuthorizationState()
        await refreshAuthorizationStatus()
        guard await shouldRefreshSchedule() else { return }

        do {
            markLastRefreshAttemptDate()
            try await withProcessingState(.refreshing) {
                _ = try await scheduleBroadcastReminderNotifications()
            }
        } catch {
            AppLogger.notifications.error(
                "Refresh today anime notification failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func refreshScheduledNotificationsImmediately() async {
        do {
            markLastRefreshAttemptDate()
            try await withProcessingState(.refreshing) {
                _ = try await scheduleBroadcastReminderNotifications()
            }
        } catch {
            AppLogger.notifications.error(
                "Immediate today anime notification refresh failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func ensureAuthorizationForSubscription() async throws {
        try await ensureAuthorization()
        setState(.enabled)
    }

    func removeReminders(forAnimeID animeID: Int) async {
        let prefix = HomeTodayAnimeNotificationConfig.broadcastReminderIdentifierPrefix(forAnimeID: animeID)
        _ = await removeManagedNotifications { $0.hasPrefix(prefix) }
    }

    func handleSubscriptionsEmptied() async {
        await removeManagedPendingNotificationRequests()
        setState(.disabled)
        clearLastRefreshDate()
    }

    private func scheduleBroadcastReminderNotifications() async throws -> Int {
        let subscriptions = subscriptionProvider()

        guard !subscriptions.isEmpty else {
            await removeManagedPendingNotificationRequests()
            setState(.disabled)
            clearLastRefreshDate()
            return 0
        }

        guard authorizationState.allowsScheduling else {
            return 0
        }

        let requests = try scheduledRequests(from: subscriptions)
        let retainedIdentifiers = Set(requests.map(\.identifier))

        switch try await addNotificationRequests(requests) {
        case .completed(let count):
            await removeManagedPendingNotificationRequests(excluding: retainedIdentifiers)
            markLastRefreshDate()
            return count
        case .skipped(.emptyRequests):
            await removeManagedPendingNotificationRequests()
            markLastRefreshDate()
            return 0
        case .skipped:
            return 0
        }
    }

    private func scheduledRequests(
        from subscriptions: [AnimeBroadcastReminderSnapshot]
    ) throws -> [UNNotificationRequest] {
        let reminders = reminderFactory.makeReminders(from: subscriptions)
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .prefix(HomeTodayAnimeNotificationConfig.maxScheduledNotifications)
        return reminders.map(requestFactory.makeRequest(for:))
    }

    private func shouldRefreshSchedule() async -> Bool {
        if let lastRefreshAttemptDate,
           Date().timeIntervalSince(lastRefreshAttemptDate) < HomeTodayAnimeNotificationConfig.failedScheduleRefreshRetryInterval {
            return false
        }

        let subscriptions = subscriptionProvider()
        if subscriptions.isEmpty {
            let pendingRequests = await pendingManagedNotificationRequests()
            return !pendingRequests.isEmpty
        }

        guard authorizationState.allowsScheduling else {
            return false
        }

        let pendingRequests = await pendingManagedNotificationRequests()
        if pendingRequests.isEmpty {
            return true
        }

        if pendingRequests.count < HomeTodayAnimeNotificationConfig.minimumHealthyPendingNotificationCount {
            return true
        }

        guard let lastRefreshDate else {
            return true
        }

        return Date().timeIntervalSince(lastRefreshDate) >= HomeTodayAnimeNotificationConfig.scheduleRefreshInterval
    }

    private func withProcessingState<T>(
        _ kind: BaseUserNotificationProcessingKind,
        operation: () async throws -> T
    ) async throws -> T {
        guard let previousState = beginProcessing(kind) else {
            throw CancellationError()
        }
        defer { restoreStateIfProcessing(previousState, expected: kind) }
        return try await operation()
    }

    private func markLastRefreshDate(_ date: Date = Date()) {
        userDefaults.set(date, forKey: HomeTodayAnimeNotificationConfig.lastRefreshDateKey)
    }

    private func markLastRefreshAttemptDate(_ date: Date = Date()) {
        userDefaults.set(date, forKey: HomeTodayAnimeNotificationConfig.lastRefreshAttemptDateKey)
    }

    private func clearLastRefreshDate() {
        userDefaults.removeObject(forKey: HomeTodayAnimeNotificationConfig.lastRefreshDateKey)
    }

    private func clearLastRefreshAttemptDate() {
        userDefaults.removeObject(forKey: HomeTodayAnimeNotificationConfig.lastRefreshAttemptDateKey)
    }
}

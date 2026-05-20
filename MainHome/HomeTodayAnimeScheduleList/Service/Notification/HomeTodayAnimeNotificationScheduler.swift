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

    private var lastRefreshDate: Date? {
        userDefaults.object(forKey: HomeTodayAnimeNotificationConfig.lastRefreshDateKey) as? Date
    }

    private var lastRefreshAttemptDate: Date? {
        userDefaults.object(forKey: HomeTodayAnimeNotificationConfig.lastRefreshAttemptDateKey) as? Date
    }

    init(
        service: HomeTodayAnimeScheduleListServicing = HomeTodayAnimeScheduleListService(),
        notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current(),
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.reminderFactory = HomeTodayAnimeBroadcastReminderFactory(service: service)
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

    func requestAuthorizationOnLaunchIfNeeded() async {
        guard await refreshAuthorizationState() == .notDetermined else { return }

        do {
            try await ensureAuthorization()
            setState(.enabled)
        } catch BaseUserNotificationError.permissionDenied {
            setState(.disabled)
        } catch {
            AppLogger.notifications.error(
                "Launch notification authorization failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func refreshAuthorizationStatus() async {
        guard await refreshAuthorizationState() == .denied else { return }
        guard state == .enabled || state == .processing(.refreshing) else { return }

        await removeManagedPendingNotificationRequests()
        setState(.disabled)
        clearLastRefreshDate()
    }

    func refreshScheduledNotificationIfNeeded() async {
        guard state == .enabled else { return }
        await refreshAuthorizationStatus()
        guard authorizationState.allowsScheduling else { return }
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

    private func scheduleBroadcastReminderNotifications() async throws -> Int {
        let requests = try await scheduledRequests()
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

    private func scheduledRequests() async throws -> [UNNotificationRequest] {
        let reminders = try await reminderFactory.makeReminders()
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .prefix(HomeTodayAnimeNotificationConfig.maxScheduledNotifications)
        return reminders.map(requestFactory.makeRequest(for:))
    }

    private func shouldRefreshSchedule() async -> Bool {
        if let lastRefreshAttemptDate,
           Date().timeIntervalSince(lastRefreshAttemptDate) < HomeTodayAnimeNotificationConfig.failedScheduleRefreshRetryInterval {
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

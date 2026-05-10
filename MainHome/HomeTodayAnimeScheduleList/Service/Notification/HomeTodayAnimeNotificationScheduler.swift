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
    static let shared = HomeTodayAnimeNotificationScheduler()

    @Published var feedback: HomeTodayAnimeNotificationFeedback?

    private let reminderFactory: HomeTodayAnimeBroadcastReminderFactory
    private let requestFactory: HomeTodayAnimeNotificationRequestFactory

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

    var reminderLeadTimeText: String {
        HomeTodayAnimeNotificationConfig.reminderLeadTimeText
    }

    func refreshAuthorizationStatus() async {
        let authorizationState = await refreshAuthorizationState()

        switch (authorizationState, state) {
        case (.denied, .enabled):
            await removeManagedPendingNotificationRequests()
            setState(.disabled)
        case (.denied, .processing(.refreshing)):
            await removeManagedPendingNotificationRequests()
            setState(.disabled)
        case (.notDetermined, _),
             (.allowed, _),
             (.denied, .disabled),
             (.denied, .processing(.enabling)),
             (.denied, .processing(.disabling)),
             (.denied, .processing(.requestingAuthorization)),
             (.denied, .processing(.scheduling)),
             (.denied, .processing(.removingPendingRequests)):
            break
        }
    }

    func toggleBroadcastReminders() async {
        switch state {
        case .enabled:
            await disableBroadcastReminders(showFeedback: true)
        case .disabled:
            await enableBroadcastReminders()
        case .processing:
            return
        }
    }

    func refreshScheduledNotificationIfNeeded() async {
        switch state {
        case .disabled, .processing:
            return
        case .enabled:
            break
        }

        await refreshAuthorizationStatus()
        guard authorizationState.allowsScheduling else { return }

        let previousState = state
        setState(.processing(.refreshing))
        defer { setState(previousState) }

        do {
            _ = try await scheduleBroadcastReminderNotifications()
        } catch {
            AppLogger.notifications.error("Refresh today anime notification failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func enableBroadcastReminders() async {
        guard let previousState = beginProcessing(.enabling) else { return }
        defer { restoreStateIfProcessing(previousState, expected: .enabling) }

        do {
            try await ensureAuthorization()
            let scheduledCount = try await scheduleBroadcastReminderNotifications()
            setState(.enabled)
            feedback = HomeTodayAnimeNotificationFeedback(
                title: "已開啟播出提醒",
                message: HomeTodayAnimeNotificationFeedbackMessage.enabled(scheduledCount: scheduledCount)
            )
        } catch BaseUserNotificationError.permissionDenied {
            setState(.disabled)
            feedback = HomeTodayAnimeNotificationFeedback(
                title: "無法開啟通知",
                message: "請到 iOS 設定允許 WYJikanApp 傳送通知後，再回來開啟今日動畫提醒。"
            )
        } catch {
            setState(.disabled)
            feedback = HomeTodayAnimeNotificationFeedback(
                title: "通知排程失敗",
                message: "目前無法取得動畫播出時間，請稍後再試一次。"
            )
            AppLogger.notifications.error("Enable today anime notification failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func disableBroadcastReminders(showFeedback: Bool) async {
        guard beginProcessing(.disabling) != nil else { return }
        await removeManagedPendingNotificationRequests()
        setState(.disabled)

        if showFeedback {
            feedback = HomeTodayAnimeNotificationFeedback(
                title: "已關閉播出提醒",
                message: "之後不會再於動畫播出前主動提醒。"
            )
        }
    }

    private func scheduleBroadcastReminderNotifications() async throws -> Int {
        await removeManagedPendingNotificationRequests()

        let reminders = try await reminderFactory.makeReminders()
            .sorted { $0.notificationDate < $1.notificationDate }
            .prefix(HomeTodayAnimeNotificationConfig.maxScheduledNotifications)
        let requests = reminders.map(requestFactory.makeRequest(for:))

        switch try await addNotificationRequests(requests) {
        case .completed(let count):
            return count
        case .skipped(.emptyRequests):
            return 0
        case .skipped:
            return 0
        }
    }
}

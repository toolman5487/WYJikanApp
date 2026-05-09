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
final class HomeTodayAnimeNotificationScheduler: ObservableObject {
    static let shared = HomeTodayAnimeNotificationScheduler()

    @Published private(set) var state: HomeTodayAnimeNotificationState
    @Published private(set) var authorizationState: HomeTodayAnimeNotificationAuthorizationState = .notDetermined
    @Published var feedback: HomeTodayAnimeNotificationFeedback?

    private let notificationCenter: UNUserNotificationCenter
    private let userDefaults: UserDefaults
    private let reminderFactory: HomeTodayAnimeBroadcastReminderFactory
    private let requestFactory: HomeTodayAnimeNotificationRequestFactory

    init(
        service: HomeTodayAnimeScheduleListServicing = HomeTodayAnimeScheduleListService(),
        notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current(),
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults
        self.reminderFactory = HomeTodayAnimeBroadcastReminderFactory(service: service)
        self.requestFactory = HomeTodayAnimeNotificationRequestFactory(calendar: calendar)
        self.state = userDefaults.bool(forKey: HomeTodayAnimeNotificationConfig.enabledKey) ? .enabled : .disabled
    }

    var reminderLeadTimeText: String {
        HomeTodayAnimeNotificationConfig.reminderLeadTimeText
    }

    func refreshAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationState = HomeTodayAnimeNotificationAuthorizationState(settings.authorizationStatus)

        switch (authorizationState, state) {
        case (.denied, .enabled):
            await removeScheduledAnimeNotifications()
            setState(.disabled)
        case (.denied, .processing(.refreshing)):
            await removeScheduledAnimeNotifications()
            setState(.disabled)
        case (.notDetermined, _), (.allowed, _), (.denied, .disabled), (.denied, .processing(.enabling)), (.denied, .processing(.disabling)):
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
        guard !state.isProcessing else { return }

        let previousState = state
        setState(.processing(.enabling))
        defer {
            if case .processing(.enabling) = state {
                setState(previousState)
            }
        }

        do {
            try await ensureAuthorization()
            let scheduledCount = try await scheduleBroadcastReminderNotifications()
            setState(.enabled)
            feedback = HomeTodayAnimeNotificationFeedback(
                title: "已開啟播出提醒",
                message: HomeTodayAnimeNotificationFeedbackMessage.enabled(scheduledCount: scheduledCount)
            )
        } catch HomeTodayAnimeNotificationError.permissionDenied {
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
        setState(.processing(.disabling))
        await removeScheduledAnimeNotifications()
        setState(.disabled)

        if showFeedback {
            feedback = HomeTodayAnimeNotificationFeedback(
                title: "已關閉播出提醒",
                message: "之後不會再於動畫播出前主動提醒。"
            )
        }
    }

    private func ensureAuthorization() async throws {
        let settings = await notificationCenter.notificationSettings()
        authorizationState = HomeTodayAnimeNotificationAuthorizationState(settings.authorizationStatus)

        switch authorizationState {
        case .allowed:
            return
        case .notDetermined:
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
            await refreshAuthorizationStatus()
            guard granted else { throw HomeTodayAnimeNotificationError.permissionDenied }
        case .denied:
            throw HomeTodayAnimeNotificationError.permissionDenied
        }
    }

    private func scheduleBroadcastReminderNotifications() async throws -> Int {
        await removeScheduledAnimeNotifications()

        let reminders = try await reminderFactory.makeReminders()
            .sorted { $0.notificationDate < $1.notificationDate }
            .prefix(HomeTodayAnimeNotificationConfig.maxScheduledNotifications)

        for reminder in reminders {
            try await notificationCenter.add(requestFactory.makeRequest(for: reminder))
        }

        return reminders.count
    }

    private func removeScheduledAnimeNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: requestFactory.managedIdentifiers(from: pendingRequests)
        )
    }

    private func setState(_ newState: HomeTodayAnimeNotificationState) {
        state = newState
        userDefaults.set(newState.isEnabled, forKey: HomeTodayAnimeNotificationConfig.enabledKey)
    }
}

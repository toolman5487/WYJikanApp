//
//  SettingPresentation.swift
//  WYJikanApp
//

import Foundation

// MARK: - Section

nonisolated enum SettingSection: CaseIterable, Identifiable, Sendable {
    case notification
    case userInformation
    case appInformation

    var id: Self { self }
}

// MARK: - User Information

nonisolated struct SettingUserInformationPresentation: Equatable, Sendable {
    let animeFavoriteCount: Int
    let mangaFavoriteCount: Int
    let reminderCount: Int
    let searchHistoryCount: Int
}

// MARK: - Notification

nonisolated enum SettingNotificationAuthorizationStatus: Equatable, Sendable {
    case loading
    case notDetermined
    case authorized
    case provisional
    case ephemeral
    case denied

    var title: String {
        switch self {
        case .loading:
            return "讀取中"
        case .notDetermined:
            return "尚未設定"
        case .authorized:
            return "已允許"
        case .provisional:
            return "暫時允許"
        case .ephemeral:
            return "本次允許"
        case .denied:
            return "已關閉"
        }
    }

    var primaryAction: SettingNotificationPrimaryAction? {
        switch self {
        case .loading:
            return nil
        case .notDetermined:
            return .requestAuthorization
        case .authorized, .provisional, .ephemeral, .denied:
            return .openSystemSettings
        }
    }

    var allowsScheduling: Bool {
        switch self {
        case .loading:
            return false
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        }
    }
}

nonisolated enum SettingNotificationPrimaryAction: Sendable {
    case requestAuthorization
    case openSystemSettings
}

nonisolated enum SettingNotificationAction: Sendable {
    case requestAuthorization
    case openSystemSettings
    case refreshReminders
}

nonisolated struct SettingNotificationPresentation: Equatable, Sendable {
    let authorizationStatus: SettingNotificationAuthorizationStatus
    let reminderCount: Int
    let refreshState: SettingActionState

    var canRefreshReminders: Bool {
        authorizationStatus.allowsScheduling
            && reminderCount > 0
            && refreshState == .idle
    }
}

nonisolated enum SettingActionState: Equatable, Sendable {
    case idle
    case processing
}

nonisolated struct SettingAppInformationPresentation: Sendable {
    let appName: String
    let versionText: String

    static func current(bundle: Bundle = .main) -> SettingAppInformationPresentation {
        let appName = bundle.object(
            forInfoDictionaryKey: "CFBundleDisplayName"
        ) as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "AniWhere"

        let version = bundle.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
        let build = bundle.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String

        return SettingAppInformationPresentation(
            appName: appName,
            versionText: versionText(version: version, build: build)
        )
    }

    private static func versionText(version: String?, build: String?) -> String {
        switch (version, build) {
        case let (version?, build?):
            return "\(version) (\(build))"
        case let (version?, nil):
            return version
        case let (nil, build?):
            return build
        case (nil, nil):
            return "-"
        }
    }
}

// MARK: - Screen Presentation

nonisolated struct SettingPresentation: Sendable {
    var userInformation: SettingUserInformationPresentation
    var notification: SettingNotificationPresentation
    let appInformation: SettingAppInformationPresentation
}

// MARK: - Alert

nonisolated enum SettingAlertMessage: Identifiable, Sendable {
    case notificationAuthorizationFailed
    case reminderRefreshSucceeded(count: Int)
    case reminderRefreshFailed

    var id: String {
        switch self {
        case .notificationAuthorizationFailed:
            return "notificationAuthorizationFailed"
        case .reminderRefreshSucceeded:
            return "reminderRefreshSucceeded"
        case .reminderRefreshFailed:
            return "reminderRefreshFailed"
        }
    }
}

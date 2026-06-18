//
//  SettingPresentation.swift
//  WYJikanApp
//

import Foundation

// MARK: - Section

nonisolated enum SettingSection: CaseIterable, Identifiable, Sendable {
    case appInformation
    case userInformation
    case notification
    case dataManagement

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
    case notDetermined
    case authorized
    case provisional
    case ephemeral
    case denied

    var title: String {
        switch self {
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

    var primaryAction: SettingNotificationAction {
        switch self {
        case .notDetermined:
            return .requestAuthorization
        case .authorized, .provisional, .ephemeral, .denied:
            return .openSystemSettings
        }
    }

    var allowsScheduling: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        }
    }
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

// MARK: - Data Management

nonisolated enum SettingDataAction: Sendable {
    case clearSearchHistory
    case clearFavorites
    case clearCache
}

nonisolated struct SettingDataManagementPresentation: Equatable, Sendable {
    let searchHistoryCount: Int
    let favoriteCount: Int
    let cacheState: SettingActionState

    var canClearSearchHistory: Bool {
        searchHistoryCount > 0
    }

    var canClearFavorites: Bool {
        favoriteCount > 0
    }
}

nonisolated enum SettingActionState: Equatable, Sendable {
    case idle
    case processing
}

// MARK: - App Information

nonisolated enum SettingDataSource: Sendable {
    case jikan

    var title: String {
        switch self {
        case .jikan:
            return "Jikan API"
        }
    }

    var url: URL? {
        switch self {
        case .jikan:
            return URL(string: "https://jikan.moe")
        }
    }
}

nonisolated struct SettingAppInformationPresentation: Sendable {
    let appName: String
    let versionText: String
    let dataSource: SettingDataSource

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
            versionText: versionText(version: version, build: build),
            dataSource: .jikan
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
    var dataManagement: SettingDataManagementPresentation
    let appInformation: SettingAppInformationPresentation
}

// MARK: - Alert

nonisolated enum SettingAlert: Identifiable, Sendable {
    case confirmation(action: SettingDataAction, count: Int)
    case message(SettingAlertMessage)

    var id: String {
        switch self {
        case .confirmation(let action, _):
            return "confirmation-\(action.id)"
        case .message(let message):
            return "message-\(message.id)"
        }
    }
}

nonisolated enum SettingAlertMessage: Sendable {
    case notificationAuthorizationFailed
    case favoriteRemovalFailed(message: String)
    case cacheCleared

    var id: String {
        switch self {
        case .notificationAuthorizationFailed:
            return "notificationAuthorizationFailed"
        case .favoriteRemovalFailed:
            return "favoriteRemovalFailed"
        case .cacheCleared:
            return "cacheCleared"
        }
    }
}

private nonisolated extension SettingDataAction {
    var id: String {
        switch self {
        case .clearSearchHistory:
            return "clearSearchHistory"
        case .clearFavorites:
            return "clearFavorites"
        case .clearCache:
            return "clearCache"
        }
    }
}

//
//  SettingPresentation.swift
//  WYJikanApp
//

import Foundation

// MARK: - Section

nonisolated enum SettingSection: CaseIterable, Identifiable, Sendable {
    case notification
    case userInformation
    case storage
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

// MARK: - Storage

nonisolated enum SettingCacheState: Equatable, Sendable {
    case loading
    case available(byteCount: Int64)
    case clearing

    var sizeText: String {
        switch self {
        case .loading:
            return "計算中"
        case .available(let byteCount):
            return ByteCountFormatter.string(
                fromByteCount: byteCount,
                countStyle: .file
            )
        case .clearing:
            return "清除中"
        }
    }

    var canClear: Bool {
        switch self {
        case .available:
            return true
        case .loading, .clearing:
            return false
        }
    }
}

nonisolated enum SettingLocalDataTarget: String, Equatable, Sendable {
    case searchHistory
    case broadcastReminders
    case favoritesAndProgress
    case all

    var title: String {
        switch self {
        case .searchHistory:
            return "搜尋紀錄"
        case .broadcastReminders:
            return "播出提醒"
        case .favoritesAndProgress:
            return "收藏與進度"
        case .all:
            return "所有本機資料"
        }
    }
}

nonisolated enum SettingLocalDataOperationState: Equatable, Sendable {
    case idle
    case deleting(SettingLocalDataTarget)

    var activeTarget: SettingLocalDataTarget? {
        switch self {
        case .idle:
            return nil
        case .deleting(let target):
            return target
        }
    }
}

nonisolated struct SettingLocalDataDeletionFailure: Error, Sendable {
    let isPartiallyCompleted: Bool
}

nonisolated struct SettingStoragePresentation: Equatable, Sendable {
    let cacheState: SettingCacheState
    let localDataOperationState: SettingLocalDataOperationState

    var isOperationInProgress: Bool {
        switch (cacheState, localDataOperationState) {
        case (.clearing, _), (_, .deleting):
            return true
        case (.loading, .idle), (.available, .idle):
            return false
        }
    }
}

// MARK: - App Information

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
    var storage: SettingStoragePresentation
    let appInformation: SettingAppInformationPresentation
}

// MARK: - Alert

nonisolated enum SettingAlertMessage: Identifiable, Sendable {
    case notificationAuthorizationFailed
    case reminderRefreshSucceeded(count: Int)
    case reminderRefreshFailed
    case confirmCacheClear(sizeText: String)
    case cacheClearSucceeded
    case cacheClearFailed
    case confirmLocalDataDeletion(
        target: SettingLocalDataTarget,
        message: String
    )
    case localDataDeletionSucceeded(SettingLocalDataTarget)
    case localDataDeletionFailed(
        target: SettingLocalDataTarget,
        partiallyCompleted: Bool
    )

    var id: String {
        switch self {
        case .notificationAuthorizationFailed:
            return "notificationAuthorizationFailed"
        case .reminderRefreshSucceeded:
            return "reminderRefreshSucceeded"
        case .reminderRefreshFailed:
            return "reminderRefreshFailed"
        case .confirmCacheClear:
            return "confirmCacheClear"
        case .cacheClearSucceeded:
            return "cacheClearSucceeded"
        case .cacheClearFailed:
            return "cacheClearFailed"
        case .confirmLocalDataDeletion(let target, _):
            return "confirmLocalDataDeletion.\(target.rawValue)"
        case .localDataDeletionSucceeded(let target):
            return "localDataDeletionSucceeded.\(target.rawValue)"
        case .localDataDeletionFailed(let target, let partiallyCompleted):
            return "localDataDeletionFailed.\(target.rawValue).\(partiallyCompleted)"
        }
    }
}

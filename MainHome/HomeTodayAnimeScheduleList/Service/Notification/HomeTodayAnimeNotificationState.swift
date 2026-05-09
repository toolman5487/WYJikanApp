//
//  HomeTodayAnimeNotificationState.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/9.
//

import UserNotifications

enum HomeTodayAnimeNotificationState: Equatable {
    case disabled
    case enabled
    case processing(HomeTodayAnimeNotificationProcessingKind)

    var isEnabled: Bool {
        switch self {
        case .enabled:
            return true
        case .disabled, .processing:
            return false
        }
    }

    var isProcessing: Bool {
        switch self {
        case .processing:
            return true
        case .disabled, .enabled:
            return false
        }
    }
}

enum HomeTodayAnimeNotificationProcessingKind: Equatable {
    case enabling
    case disabling
    case refreshing
}

enum HomeTodayAnimeNotificationAuthorizationState: Equatable {
    case notDetermined
    case allowed
    case denied

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized, .provisional, .ephemeral:
            self = .allowed
        case .denied:
            self = .denied
        case .notDetermined:
            self = .notDetermined
        @unknown default:
            self = .denied
        }
    }

    var allowsScheduling: Bool {
        switch self {
        case .allowed:
            return true
        case .notDetermined, .denied:
            return false
        }
    }
}

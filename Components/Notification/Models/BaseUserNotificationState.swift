//
//  BaseUserNotificationState.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/10.
//

import UserNotifications

enum BaseUserNotificationState: Equatable {
    case disabled
    case enabled
    case processing(BaseUserNotificationProcessingKind)

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

enum BaseUserNotificationProcessingKind: Equatable {
    case enabling
    case disabling
    case refreshing
    case requestingAuthorization
    case scheduling
    case removingPendingRequests
}

enum BaseUserNotificationAuthorizationState: Equatable {
    case notDetermined
    case allowed(BaseUserNotificationAuthorizationLevel)
    case denied

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized:
            self = .allowed(.authorized)
        case .provisional:
            self = .allowed(.provisional)
        case .ephemeral:
            self = .allowed(.ephemeral)
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

enum BaseUserNotificationAuthorizationLevel: Equatable {
    case authorized
    case provisional
    case ephemeral
}

enum BaseUserNotificationOperationResult: Equatable {
    case completed(count: Int)
    case skipped(BaseUserNotificationSkipReason)
}

enum BaseUserNotificationSkipReason: Equatable {
    case disabled
    case processing
    case authorizationDenied
    case authorizationNotDetermined
    case emptyRequests
}

enum BaseUserNotificationError: LocalizedError {
    case permissionDenied
    case requestAuthorizationFailed(Error)
    case scheduleFailed(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission was denied."
        case .requestAuthorizationFailed(let error):
            return "Notification authorization failed: \(error.localizedDescription)"
        case .scheduleFailed(let error):
            return "Notification scheduling failed: \(error.localizedDescription)"
        }
    }
}

//
//  BaseUserNotificationManager.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/10.
//

import Combine
import Foundation
import UserNotifications

@MainActor
class BaseUserNotificationManager: ObservableObject {
    @Published private(set) var state: BaseUserNotificationState
    @Published private(set) var authorizationState: BaseUserNotificationAuthorizationState = .notDetermined

    let notificationCenter: UNUserNotificationCenter
    let userDefaults: UserDefaults

    private let enabledKey: String
    private let managedIdentifierPrefixes: [String]

    init(
        enabledKey: String,
        managedIdentifierPrefixes: [String],
        notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current(),
        userDefaults: UserDefaults = .standard
    ) {
        self.enabledKey = enabledKey
        self.managedIdentifierPrefixes = managedIdentifierPrefixes
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults
        self.state = userDefaults.bool(forKey: enabledKey) ? .enabled : .disabled
    }

    @discardableResult
    func refreshAuthorizationState() async -> BaseUserNotificationAuthorizationState {
        let settings = await notificationCenter.notificationSettings()
        authorizationState = BaseUserNotificationAuthorizationState(settings.authorizationStatus)
        return authorizationState
    }

    func ensureAuthorization(
        options: UNAuthorizationOptions = [.alert, .sound]
    ) async throws {
        switch await refreshAuthorizationState() {
        case .allowed:
            return
        case .notDetermined:
            do {
                let granted = try await notificationCenter.requestAuthorization(options: options)
                await refreshAuthorizationState()
                guard granted else { throw BaseUserNotificationError.permissionDenied }
            } catch let error as BaseUserNotificationError {
                throw error
            } catch {
                throw BaseUserNotificationError.requestAuthorizationFailed(error)
            }
        case .denied:
            throw BaseUserNotificationError.permissionDenied
        }
    }

    func setState(_ newState: BaseUserNotificationState) {
        state = newState

        switch newState {
        case .enabled:
            userDefaults.set(true, forKey: enabledKey)
        case .disabled:
            userDefaults.set(false, forKey: enabledKey)
        case .processing:
            break
        }
    }

    func beginProcessing(_ kind: BaseUserNotificationProcessingKind) -> BaseUserNotificationState? {
        guard !state.isProcessing else { return nil }
        let previousState = state
        setState(.processing(kind))
        return previousState
    }

    func restoreStateIfProcessing(
        _ previousState: BaseUserNotificationState,
        expected kind: BaseUserNotificationProcessingKind
    ) {
        switch state {
        case .processing(let currentKind) where currentKind == kind:
            setState(previousState)
        case .disabled, .enabled, .processing:
            break
        }
    }

    func addNotificationRequests(_ requests: [UNNotificationRequest]) async throws -> BaseUserNotificationOperationResult {
        guard !requests.isEmpty else { return .skipped(.emptyRequests) }

        do {
            for request in requests {
                try await notificationCenter.add(request)
            }
            return .completed(count: requests.count)
        } catch {
            throw BaseUserNotificationError.scheduleFailed(error)
        }
    }

    func isManagedNotificationIdentifier(_ identifier: String) -> Bool {
        managedIdentifierPrefixes.contains { identifier.hasPrefix($0) }
    }

    func pendingManagedNotificationRequests() async -> [UNNotificationRequest] {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        return pendingRequests.filter { request in
            isManagedNotificationIdentifier(request.identifier)
        }
    }

    @discardableResult
    func removeManagedNotifications(where identifierMatches: (String) -> Bool) async -> Int {
        let pendingIdentifiers = await pendingManagedNotificationRequests()
            .map(\.identifier)
            .filter(identifierMatches)
        if !pendingIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers)
        }

        let deliveredIdentifiers = await notificationCenter.deliveredNotifications()
            .map(\.request.identifier)
            .filter { identifier in
                isManagedNotificationIdentifier(identifier) && identifierMatches(identifier)
            }
        if !deliveredIdentifiers.isEmpty {
            notificationCenter.removeDeliveredNotifications(withIdentifiers: deliveredIdentifiers)
        }

        return pendingIdentifiers.count + deliveredIdentifiers.count
    }

    @discardableResult
    func removeManagedPendingNotificationRequests() async -> Int {
        let pendingRequests = await pendingManagedNotificationRequests()
        let identifiers = pendingRequests.map(\.identifier)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        return identifiers.count
    }

    @discardableResult
    func removeManagedPendingNotificationRequests(
        excluding retainedIdentifiers: Set<String>
    ) async -> Int {
        let pendingRequests = await pendingManagedNotificationRequests()
        let identifiersToRemove = pendingRequests
            .map(\.identifier)
            .filter { !retainedIdentifiers.contains($0) }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        return identifiersToRemove.count
    }
}

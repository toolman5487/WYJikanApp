//
//  SettingViewModel.swift
//  WYJikanApp
//

import Combine
import Foundation

@MainActor
final class SettingViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var presentation: SettingPresentation
    @Published var presentedAlert: SettingAlert?

    // MARK: - Dependencies

    private let service: any SettingServicing
    private let notificationScheduler: HomeTodayAnimeNotificationScheduler
    private let broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore
    private let favoriteStatusStore: FavoriteStatusStore

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(
        service: any SettingServicing,
        notificationScheduler: HomeTodayAnimeNotificationScheduler,
        broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore,
        favoriteStatusStore: FavoriteStatusStore,
        appInformation: SettingAppInformationPresentation = .current()
    ) {
        self.service = service
        self.notificationScheduler = notificationScheduler
        self.broadcastReminderStatusStore = broadcastReminderStatusStore
        self.favoriteStatusStore = favoriteStatusStore
        self.presentation = SettingPresentation(
            notification: SettingNotificationPresentation(
                authorizationStatus: Self.authorizationStatus(
                    from: notificationScheduler.authorizationState
                ),
                reminderCount: broadcastReminderStatusStore.subscriptions.count,
                refreshState: Self.actionState(from: notificationScheduler.state)
            ),
            dataManagement: SettingDataManagementPresentation(
                searchHistoryCount: service.searchHistoryCount(),
                favoriteCount: favoriteStatusStore.totalFavoriteCount,
                cacheState: .idle
            ),
            appInformation: appInformation
        )

        bindNotificationState()
        bindFavoriteState()
    }

    // MARK: - Public Actions

    func refresh() async {
        updateSearchHistoryCount()
        await notificationScheduler.refreshAuthorizationState()
        rebuildNotificationPresentation()
    }

    func performNotificationAction(_ action: SettingNotificationAction) async {
        switch action {
        case .requestAuthorization:
            await requestNotificationAuthorization()
        case .openSystemSettings:
            break
        case .refreshReminders:
            await notificationScheduler.refreshScheduledNotificationsImmediately()
        }
    }

    func requestDataAction(_ action: SettingDataAction) {
        switch action {
        case .clearSearchHistory:
            presentedAlert = .confirmation(
                action: action,
                count: presentation.dataManagement.searchHistoryCount
            )
        case .clearFavorites:
            presentedAlert = .confirmation(
                action: action,
                count: presentation.dataManagement.favoriteCount
            )
        case .clearCache:
            presentedAlert = .confirmation(action: action, count: 0)
        }
    }

    func confirmPresentedAlert() {
        guard let presentedAlert else { return }
        self.presentedAlert = nil

        switch presentedAlert {
        case .confirmation(let action, _):
            performConfirmedDataAction(action)
        case .message:
            break
        }
    }

    func dismissPresentedAlert() {
        presentedAlert = nil
    }

    // MARK: - Binding

    private func bindNotificationState() {
        Publishers.CombineLatest3(
            notificationScheduler.$authorizationState,
            notificationScheduler.$state,
            broadcastReminderStatusStore.$subscriptions
        )
        .sink { [weak self] _, _, _ in
            self?.rebuildNotificationPresentation()
        }
        .store(in: &cancellables)
    }

    private func bindFavoriteState() {
        Publishers.CombineLatest(
            favoriteStatusStore.$animeFavoriteIDs,
            favoriteStatusStore.$mangaFavoriteIDs
        )
        .sink { [weak self] animeIDs, mangaIDs in
            self?.updateFavoriteCount(animeIDs.count + mangaIDs.count)
        }
        .store(in: &cancellables)
    }

    // MARK: - Notification

    private func requestNotificationAuthorization() async {
        do {
            try await notificationScheduler.ensureAuthorization()
            await notificationScheduler.refreshScheduledNotificationsImmediately()
        } catch {
            presentedAlert = .message(.notificationAuthorizationFailed)
        }
    }

    private func rebuildNotificationPresentation() {
        presentation.notification = SettingNotificationPresentation(
            authorizationStatus: Self.authorizationStatus(
                from: notificationScheduler.authorizationState
            ),
            reminderCount: broadcastReminderStatusStore.subscriptions.count,
            refreshState: Self.actionState(from: notificationScheduler.state)
        )
    }

    private static func authorizationStatus(
        from state: BaseUserNotificationAuthorizationState
    ) -> SettingNotificationAuthorizationStatus {
        switch state {
        case .notDetermined:
            return .notDetermined
        case .allowed(.authorized):
            return .authorized
        case .allowed(.provisional):
            return .provisional
        case .allowed(.ephemeral):
            return .ephemeral
        case .denied:
            return .denied
        }
    }

    private static func actionState(
        from state: BaseUserNotificationState
    ) -> SettingActionState {
        switch state {
        case .disabled, .enabled:
            return .idle
        case .processing:
            return .processing
        }
    }

    // MARK: - Data Management

    private func performConfirmedDataAction(_ action: SettingDataAction) {
        switch action {
        case .clearSearchHistory:
            service.clearSearchHistory()
            updateSearchHistoryCount()
        case .clearFavorites:
            clearFavorites()
        case .clearCache:
            clearCache()
        }
    }

    private func clearFavorites() {
        do {
            try service.clearFavorites()
        } catch {
            presentedAlert = .message(
                .favoriteRemovalFailed(message: error.localizedDescription)
            )
        }
    }

    private func clearCache() {
        updateCacheState(.processing)

        Task(priority: .utility) { [weak self] in
            guard let self else { return }

            await service.clearCachedData()
            updateCacheState(.idle)
            presentedAlert = .message(.cacheCleared)
        }
    }

    private func updateSearchHistoryCount() {
        presentation.dataManagement = SettingDataManagementPresentation(
            searchHistoryCount: service.searchHistoryCount(),
            favoriteCount: presentation.dataManagement.favoriteCount,
            cacheState: presentation.dataManagement.cacheState
        )
    }

    private func updateFavoriteCount(_ count: Int) {
        presentation.dataManagement = SettingDataManagementPresentation(
            searchHistoryCount: presentation.dataManagement.searchHistoryCount,
            favoriteCount: count,
            cacheState: presentation.dataManagement.cacheState
        )
    }

    private func updateCacheState(_ state: SettingActionState) {
        presentation.dataManagement = SettingDataManagementPresentation(
            searchHistoryCount: presentation.dataManagement.searchHistoryCount,
            favoriteCount: presentation.dataManagement.favoriteCount,
            cacheState: state
        )
    }
}

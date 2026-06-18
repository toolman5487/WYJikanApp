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
    @Published var presentedAlert: SettingAlertMessage?

    // MARK: - Dependencies

    private let service: any SettingServicing
    private let notificationScheduler: HomeTodayAnimeNotificationScheduler
    private let broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore
    private let favoriteStatusStore: FavoriteStatusStore

    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedAuthorizationState = false

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
        let searchHistoryCount = service.searchHistoryCount()
        self.presentation = SettingPresentation(
            userInformation: SettingUserInformationPresentation(
                animeFavoriteCount: favoriteStatusStore.animeFavoriteIDs.count,
                mangaFavoriteCount: favoriteStatusStore.mangaFavoriteIDs.count,
                reminderCount: broadcastReminderStatusStore.subscriptions.count,
                searchHistoryCount: searchHistoryCount
            ),
            notification: SettingNotificationPresentation(
                authorizationStatus: .loading,
                reminderCount: broadcastReminderStatusStore.subscriptions.count,
                refreshState: Self.actionState(from: notificationScheduler.state)
            ),
            appInformation: appInformation
        )

        bindNotificationState()
        bindFavoriteState()
        bindSearchHistoryState()
    }

    // MARK: - Public Actions

    func refresh() async {
        updateSearchHistoryCount()
        await notificationScheduler.refreshAuthorizationState()
        hasLoadedAuthorizationState = true
        rebuildNotificationPresentation()
    }

    func performNotificationAction(_ action: SettingNotificationAction) async {
        switch action {
        case .requestAuthorization:
            await requestNotificationAuthorization()
        case .openSystemSettings:
            break
        case .refreshReminders:
            await refreshReminders()
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
            self?.rebuildUserInformationPresentation()
        }
        .store(in: &cancellables)
    }

    private func bindFavoriteState() {
        Publishers.CombineLatest(
            favoriteStatusStore.$animeFavoriteIDs,
            favoriteStatusStore.$mangaFavoriteIDs
        )
        .sink { [weak self] animeIDs, mangaIDs in
            self?.updateFavoriteCounts(
                animeCount: animeIDs.count,
                mangaCount: mangaIDs.count
            )
        }
        .store(in: &cancellables)
    }

    private func bindSearchHistoryState() {
        service.searchHistoryCountPublisher
            .sink { [weak self] count in
                self?.updateSearchHistoryCount(count)
            }
            .store(in: &cancellables)
    }

    // MARK: - Notification

    private func requestNotificationAuthorization() async {
        do {
            try await notificationScheduler.ensureAuthorization()
        } catch {
            presentedAlert = .notificationAuthorizationFailed
            return
        }

        hasLoadedAuthorizationState = true
        rebuildNotificationPresentation()
        await refreshReminders()
    }

    private func refreshReminders() async {
        do {
            let count = try await notificationScheduler
                .refreshScheduledNotificationsImmediatelyReportingFailure()
            presentedAlert = .reminderRefreshSucceeded(count: count)
        } catch {
            presentedAlert = .reminderRefreshFailed
        }
    }

    private func rebuildNotificationPresentation() {
        presentation.notification = SettingNotificationPresentation(
            authorizationStatus: hasLoadedAuthorizationState
                ? Self.authorizationStatus(from: notificationScheduler.authorizationState)
                : .loading,
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

    private func updateSearchHistoryCount() {
        updateSearchHistoryCount(service.searchHistoryCount())
    }

    private func updateSearchHistoryCount(_ searchHistoryCount: Int) {
        presentation.userInformation = SettingUserInformationPresentation(
            animeFavoriteCount: presentation.userInformation.animeFavoriteCount,
            mangaFavoriteCount: presentation.userInformation.mangaFavoriteCount,
            reminderCount: presentation.userInformation.reminderCount,
            searchHistoryCount: searchHistoryCount
        )
    }

    private func updateFavoriteCounts(animeCount: Int, mangaCount: Int) {
        presentation.userInformation = SettingUserInformationPresentation(
            animeFavoriteCount: animeCount,
            mangaFavoriteCount: mangaCount,
            reminderCount: presentation.userInformation.reminderCount,
            searchHistoryCount: presentation.userInformation.searchHistoryCount
        )
    }

    private func rebuildUserInformationPresentation() {
        presentation.userInformation = SettingUserInformationPresentation(
            animeFavoriteCount: favoriteStatusStore.animeFavoriteIDs.count,
            mangaFavoriteCount: favoriteStatusStore.mangaFavoriteIDs.count,
            reminderCount: broadcastReminderStatusStore.subscriptions.count,
            searchHistoryCount: presentation.userInformation.searchHistoryCount
        )
    }
}

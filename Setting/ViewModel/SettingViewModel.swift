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
    private var searchHistoryCount: Int

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
        self.searchHistoryCount = searchHistoryCount
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
            storage: SettingStoragePresentation(
                cacheState: .loading,
                localDataOperationState: .idle
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
        await refreshCacheSize()
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

    func requestCacheClearConfirmation() {
        guard !presentation.storage.isOperationInProgress else { return }
        presentedAlert = .confirmCacheClear(
            sizeText: presentation.storage.cacheState.sizeText
        )
    }

    func clearCache() async {
        guard !presentation.storage.isOperationInProgress else { return }
        updateCacheState(.clearing)

        do {
            try await service.clearCache()
            updateCacheState(.available(byteCount: 0))
            presentedAlert = .cacheClearSucceeded
        } catch {
            await refreshCacheSize()
            presentedAlert = .cacheClearFailed
        }
    }

    func requestLocalDataDeletionConfirmation(
        _ target: SettingLocalDataTarget
    ) {
        guard !presentation.storage.isOperationInProgress else { return }
        presentedAlert = .confirmLocalDataDeletion(
            target: target,
            message: localDataDeletionConfirmationMessage(for: target)
        )
    }

    func deleteLocalData(_ target: SettingLocalDataTarget) async {
        guard !presentation.storage.isOperationInProgress else { return }
        updateLocalDataOperationState(.deleting(target))

        do {
            try await service.deleteLocalData(target)
            updateLocalDataOperationState(.idle)
            presentedAlert = .localDataDeletionSucceeded(target)
        } catch let failure as SettingLocalDataDeletionFailure {
            updateLocalDataOperationState(.idle)
            presentedAlert = .localDataDeletionFailed(
                target: target,
                partiallyCompleted: failure.isPartiallyCompleted
            )
        } catch {
            updateLocalDataOperationState(.idle)
            presentedAlert = .localDataDeletionFailed(
                target: target,
                partiallyCompleted: false
            )
        }
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
            self?.rebuildUserInformationPresentation(
                animeCount: animeIDs.count,
                mangaCount: mangaIDs.count
            )
        }
        .store(in: &cancellables)
    }

    private func bindSearchHistoryState() {
        service.searchHistoryCountPublisher
            .sink { [weak self] count in
                self?.searchHistoryCount = count
                self?.rebuildUserInformationPresentation()
            }
            .store(in: &cancellables)
    }

    // MARK: - Storage

    private func refreshCacheSize() async {
        guard presentation.storage.cacheState != .clearing else { return }

        updateCacheState(.loading)
        let byteCount = await service.cacheSize()
        updateCacheState(.available(byteCount: byteCount))
    }

    private func updateCacheState(_ state: SettingCacheState) {
        presentation.storage = SettingStoragePresentation(
            cacheState: state,
            localDataOperationState: presentation.storage.localDataOperationState
        )
    }

    private func updateLocalDataOperationState(
        _ state: SettingLocalDataOperationState
    ) {
        presentation.storage = SettingStoragePresentation(
            cacheState: presentation.storage.cacheState,
            localDataOperationState: state
        )
    }

    private var totalFavoriteCount: Int {
        presentation.userInformation.animeFavoriteCount
            + presentation.userInformation.mangaFavoriteCount
    }

    private func localDataDeletionConfirmationMessage(
        for target: SettingLocalDataTarget
    ) -> String {
        switch target {
        case .searchHistory:
            return "將永久刪除 \(presentation.userInformation.searchHistoryCount) 筆搜尋紀錄。"
        case .broadcastReminders:
            return "將永久刪除 \(presentation.userInformation.reminderCount) 部播出提醒，並移除已排程的系統通知。"
        case .favoritesAndProgress:
            return "將永久刪除 \(totalFavoriteCount) 部收藏，以及所有動畫觀看與漫畫閱讀進度。"
        case .all:
            return "將永久刪除收藏與進度、播出提醒、已排程系統通知及搜尋紀錄。此操作無法復原。"
        }
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
        case .disabled:
            return .idle
        case .enabled:
            return .idle
        case .processing:
            return .processing
        }
    }

    private func updateSearchHistoryCount() {
        searchHistoryCount = service.searchHistoryCount()
        rebuildUserInformationPresentation()
    }

    private func rebuildUserInformationPresentation(
        animeCount: Int? = nil,
        mangaCount: Int? = nil
    ) {
        presentation.userInformation = SettingUserInformationPresentation(
            animeFavoriteCount: animeCount
                ?? favoriteStatusStore.animeFavoriteIDs.count,
            mangaFavoriteCount: mangaCount
                ?? favoriteStatusStore.mangaFavoriteIDs.count,
            reminderCount: broadcastReminderStatusStore.subscriptions.count,
            searchHistoryCount: searchHistoryCount
        )
    }
}

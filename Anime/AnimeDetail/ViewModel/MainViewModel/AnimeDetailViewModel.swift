//
//  AnimeDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Combine
import Foundation
import OSLog
@MainActor
final class AnimeDetailViewModel: ObservableObject {
    enum ScreenState {
        case idle
        case loading
        case refreshing(AnimeDetailDTO)
        case loaded(AnimeDetailDTO)
        case error(FeatureLoadFailure)
    }

    @Published private(set) var screenState: ScreenState = .idle
    @Published private(set) var pictureItems: [AnimeDetailPictureItem] = []
    @Published private(set) var characterRoles: [AnimeCharacterRoleDTO] = []
    @Published private(set) var recommendationItems: [AnimeRecommendationDTO] = []
    @Published private(set) var isLoadingCharacters = false
    @Published private(set) var isLoadingPictures = false
    @Published private(set) var isLoadingRecommendations = false
    @Published private(set) var charactersFailure: FeatureLoadFailure?
    @Published private(set) var picturesFailure: FeatureLoadFailure?
    @Published private(set) var recommendationsFailure: FeatureLoadFailure?

    private let malId: Int
    private let service: AnimeDetailServicing
    private let favoriteRepository: any FavoriteRepository
    private let broadcastReminderRepository: any AnimeBroadcastReminderRepository

    init(
        malId: Int,
        service: AnimeDetailServicing,
        favoriteRepository: any FavoriteRepository,
        broadcastReminderRepository: any AnimeBroadcastReminderRepository
    ) {
        self.malId = malId
        self.service = service
        self.favoriteRepository = favoriteRepository
        self.broadcastReminderRepository = broadcastReminderRepository
    }

    var detail: AnimeDetailDTO? {
        switch screenState {
        case let .refreshing(detail), let .loaded(detail):
            return detail
        case .idle, .loading, .error:
            return nil
        }
    }

    var isRefreshing: Bool {
        if case .refreshing = screenState {
            return true
        }
        return false
    }

    private var isInitialLoading: Bool {
        if case .loading = screenState {
            return true
        }
        return false
    }

    // MARK: - Load

    func load(forceRefresh: Bool = false) async {
        let existingDetail = detail
        guard forceRefresh || existingDetail == nil else { return }
        guard !isRefreshing, !(existingDetail == nil && isInitialLoading) else { return }

        if existingDetail == nil {
            screenState = .loading
            resetSupplementaryContent()
        } else if let existingDetail {
            screenState = .refreshing(existingDetail)
        }

        do {
            let resolvedDetail = try await service.fetchAnimeDetail(malId: malId)
            let detail = resolvedDetail.data
            screenState = .loaded(detail)
            await loadSupplementaryContent(resetOnFailure: existingDetail == nil)
        } catch is CancellationError {
            return
        } catch {
            if let existingDetail, forceRefresh {
                screenState = .loaded(existingDetail)
            } else {
                screenState = .error(FeatureLoadFailure(error))
                resetSupplementaryContent()
            }
        }
    }

    private func loadSupplementaryContent(resetOnFailure: Bool) async {
        await loadCharacters(resetOnFailure: resetOnFailure)
        await loadPictures(resetOnFailure: resetOnFailure)
        await loadRecommendations(resetOnFailure: resetOnFailure)
    }

    func reloadCharacters() async {
        await loadCharacters(resetOnFailure: false)
    }

    func reloadPictures() async {
        await loadPictures(resetOnFailure: false)
    }

    func reloadRecommendations() async {
        await loadRecommendations(resetOnFailure: false)
    }

    private func loadPictures(resetOnFailure: Bool) async {
        isLoadingPictures = true
        if resetOnFailure {
            picturesFailure = nil
        }
        defer { isLoadingPictures = false }

        do {
            let resolvedPictures = try await service.fetchAnimePictures(malId: malId)
            pictureItems = AnimeDetailPictureMapping.items(from: resolvedPictures)
            picturesFailure = nil
        } catch is CancellationError {
        } catch {
            picturesFailure = FeatureLoadFailure(error)
            if resetOnFailure {
                pictureItems = []
            }
        }
    }

    private func loadCharacters(resetOnFailure: Bool) async {
        isLoadingCharacters = true
        if resetOnFailure {
            charactersFailure = nil
        }
        defer { isLoadingCharacters = false }

        do {
            let resolvedCharacters = try await service.fetchAnimeCharacters(malId: malId)
            characterRoles = resolvedCharacters.data
            charactersFailure = nil
        } catch is CancellationError {
        } catch {
            charactersFailure = FeatureLoadFailure(error)
            if resetOnFailure {
                characterRoles = []
            }
        }
    }

    private func loadRecommendations(resetOnFailure: Bool) async {
        isLoadingRecommendations = true
        if resetOnFailure {
            recommendationsFailure = nil
        }
        defer { isLoadingRecommendations = false }

        do {
            let resolvedRecommendations = try await service.fetchAnimeRecommendations(malId: malId)
            recommendationItems = resolvedRecommendations.data
            recommendationsFailure = nil
        } catch is CancellationError {
        } catch {
            recommendationsFailure = FeatureLoadFailure(error)
            if resetOnFailure {
                recommendationItems = []
            }
        }
    }

    private func resetSupplementaryContent() {
        pictureItems = []
        characterRoles = []
        recommendationItems = []
        isLoadingCharacters = false
        isLoadingPictures = false
        isLoadingRecommendations = false
        charactersFailure = nil
        picturesFailure = nil
        recommendationsFailure = nil
    }

    var isFavoriteActionEnabled: Bool {
        detail != nil
    }

    func toggleFavorite(isFavorite: Bool) {
        do {
            if isFavorite {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .anime,
                    makeItem: nil
                )
            } else if let detail {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .anime,
                    makeItem: { self.favoriteItem(for: detail) }
                )
            }
        } catch {
            AppLogger.persistence.error("Anime favorite update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Broadcast Reminder

    func syncBroadcastReminderIfNeeded(
        isSubscribed: Bool,
        subscribedCount: Int,
        notificationScheduler: HomeTodayAnimeNotificationScheduler
    ) async {
        guard let detail else { return }

        await AnimeBroadcastReminderReconciler.reconcile(
            anime: detail,
            isSubscribed: isSubscribed,
            subscribedCount: subscribedCount,
            repository: broadcastReminderRepository,
            scheduler: notificationScheduler
        )
    }

    func toggleBroadcastReminder(
        isSubscribed: Bool,
        subscribedCount: Int,
        notificationScheduler: HomeTodayAnimeNotificationScheduler
    ) async -> AnimeDetailBroadcastReminderError? {
        guard let detail else {
            return .detailUnavailable
        }

        do {
            if isSubscribed {
                await AnimeBroadcastReminderReconciler.unsubscribe(
                    malId: detail.id,
                    remainingSubscriptionCount: subscribedCount - 1,
                    repository: broadcastReminderRepository,
                    scheduler: notificationScheduler
                )
                return nil
            }

            guard let snapshot = AnimeBroadcastReminderSnapshot(
                anime: detail,
                title: displayTitle(for: detail)
            ) else {
                return .broadcastUnavailable
            }

            do {
                try await notificationScheduler.ensureAuthorizationForSubscription()
            } catch BaseUserNotificationError.permissionDenied {
                return .permissionDenied
            }

            try broadcastReminderRepository.subscribe(snapshot: snapshot)
            await notificationScheduler.refreshScheduledNotificationsImmediately()
            return nil
        } catch {
            AppLogger.persistence.error(
                "Anime broadcast reminder update failed: \(error.localizedDescription, privacy: .public)"
            )
            return .broadcastUnavailable
        }
    }
}

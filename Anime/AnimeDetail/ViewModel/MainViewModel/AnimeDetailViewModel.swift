//
//  AnimeDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Combine
import Foundation
import FoundationModels
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

    enum SynopsisTranslationState: Equatable {
        case idle
        case translating
        case translated(String)
        case failed(String)
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
    @Published private(set) var favoriteCollectionItem: MyListCollectionItem?
    @Published private(set) var synopsisTranslationState: SynopsisTranslationState = .idle

    private let malId: Int
    private let service: AnimeDetailServicing
    private let favoriteRepository: any FavoriteRepository
    private let broadcastReminderRepository: any AnimeBroadcastReminderRepository
    private let watchProgressController: AnimeWatchProgressController
    private var myListCancellable: AnyCancellable?
    private var synopsisTranslationTask: Task<Void, Never>?

    init(
        malId: Int,
        service: AnimeDetailServicing,
        favoriteRepository: any FavoriteRepository,
        broadcastReminderRepository: any AnimeBroadcastReminderRepository,
        watchProgressController: AnimeWatchProgressController = AnimeWatchProgressController()
    ) {
        self.malId = malId
        self.service = service
        self.favoriteRepository = favoriteRepository
        self.broadcastReminderRepository = broadcastReminderRepository
        self.watchProgressController = watchProgressController
        connectToMyList()
    }

    deinit {
        synopsisTranslationTask?.cancel()
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
            resetSynopsisTranslationIfNeeded(for: detail)
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
        async let pictures: Void = loadPictures(resetOnFailure: resetOnFailure)
        async let recommendations: Void = loadRecommendations(resetOnFailure: resetOnFailure)
        _ = await (pictures, recommendations)
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

    // MARK: - Synopsis Translation

    var isTranslatingSynopsis: Bool {
        if case .translating = synopsisTranslationState {
            return true
        }
        return false
    }

    var synopsisTranslationButtonTitle: String {
        switch synopsisTranslationState {
        case .idle, .failed:
            return "翻譯劇情"
        case .translating:
            return "翻譯中"
        case .translated:
            return "重新翻譯"
        }
    }

    func requestSynopsisTranslation(for anime: AnimeDetailDTO) {
        let synopsis = synopsisDisplayText(for: anime)
        guard synopsis != "-" else {
            synopsisTranslationState = .failed("沒有可翻譯的作品簡介。")
            return
        }

        synopsisTranslationTask?.cancel()
        synopsisTranslationState = .translating

        synopsisTranslationTask = Task { [weak self] in
            let translationState = await Self.translateSynopsis(synopsis)
            guard !Task.isCancelled else { return }
            self?.synopsisTranslationState = translationState
        }
    }

    private func resetSynopsisTranslationIfNeeded(for anime: AnimeDetailDTO) {
        guard synopsisTranslationState != .idle else { return }
        synopsisTranslationTask?.cancel()
        synopsisTranslationState = .idle
    }

    private nonisolated static func translateSynopsis(
        _ synopsis: String
    ) async -> SynopsisTranslationState {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            break

        case let .unavailable(reason):
            return .failed(availabilityMessage(for: reason))
        }

        do {
            let session = LanguageModelSession(
                model: model,
                instructions: """
                你是動漫作品簡介翻譯助手。只輸出繁體中文譯文，不要加入解釋、標題、評論或額外內容。
                保留角色名、作品專有名詞與括號中的來源標記原意，語氣自然但不要改寫劇情。
                """
            )
            let prompt = """
            請將以下英文動畫劇情簡介翻譯成繁體中文：

            \(synopsis)
            """
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(temperature: 0.1, maximumResponseTokens: 1_200)
            )
            let translatedText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !translatedText.isEmpty else {
                return .failed("本地 AI 沒有產生可顯示內容。")
            }

            return .translated(translatedText)
        } catch is CancellationError {
            return .idle
        } catch {
            return .failed("本地 AI 翻譯暫時無法使用。")
        }
    }

    private nonisolated static func availabilityMessage(
        for reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            return "此裝置不支援本地 AI 翻譯。"
        case .appleIntelligenceNotEnabled:
            return "請先在系統設定開啟 Apple Intelligence，才能使用本地 AI 翻譯。"
        case .modelNotReady:
            return "本地 AI 模型尚未準備完成，稍後再試。"
        @unknown default:
            return "此裝置目前無法使用本地 AI 翻譯。"
        }
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

    // MARK: - MyList

    private func connectToMyList() {
        myListCancellable = favoriteRepository.myListPublisher
            .sink { [weak self] items in
                guard let self else { return }
                favoriteCollectionItem = items.first { item in
                    item.malId == malId && item.mediaKind == .anime
                }
            }
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

    func updateWatchProgress(
        for item: MyListCollectionItem,
        status: AnimeWatchStatus,
        currentEpisode: Int?,
        totalEpisodes: Int?
    ) {
        item.updateAnimeWatchProgress(
            status: status,
            currentEpisode: currentEpisode,
            totalEpisodes: totalEpisodes
        )

        do {
            try favoriteRepository.saveChanges()
        } catch {
            AppLogger.persistence.error("Anime watch progress update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func watchProgressEditorDraft(
        for item: MyListCollectionItem,
        anime: AnimeDetailDTO
    ) -> AnimeWatchProgressEditorDraft {
        watchProgressController.editorDraft(for: item, anime: anime)
    }

    func incrementWatchProgress(
        for item: MyListCollectionItem,
        anime: AnimeDetailDTO
    ) {
        let update = watchProgressController.incrementUpdate(for: item, anime: anime)

        updateWatchProgress(
            for: item,
            status: update.status,
            currentEpisode: update.currentEpisode,
            totalEpisodes: update.totalEpisodes
        )
    }

    func decrementWatchProgress(
        for item: MyListCollectionItem,
        anime: AnimeDetailDTO
    ) {
        let update = watchProgressController.decrementUpdate(for: item, anime: anime)

        updateWatchProgress(
            for: item,
            status: update.status,
            currentEpisode: update.currentEpisode,
            totalEpisodes: update.totalEpisodes
        )
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

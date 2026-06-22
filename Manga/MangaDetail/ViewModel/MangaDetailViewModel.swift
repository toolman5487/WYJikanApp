//
//  MangaDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import Combine
import Foundation

@MainActor
final class MangaDetailViewModel: ObservableObject {

    // MARK: - Types

    enum ScreenState {
        case idle
        case loading
        case refreshing(MangaDetailDTO)
        case loaded(MangaDetailDTO)
        case error(FeatureLoadFailure)
    }

    @Published private(set) var screenState: ScreenState = .idle
    @Published private(set) var favoriteCollectionItem: MyListItemSnapshot?
    @Published private(set) var persistenceMutationState: PersistenceMutationState = .idle
    let picturesState = DetailSupplementaryState<[MangaDetailPictureItem]>(initialValue: [])
    let charactersState = DetailSupplementaryState<[MangaCharacterRoleDTO]>(initialValue: [])
    let recommendationsState = DetailSupplementaryState<[MangaRecommendationDTO]>(initialValue: [])
    let synopsisTranslationViewModel: SynopsisTranslationViewModel

    // MARK: - Dependencies

    private let malId: Int
    private let service: MangaDetailServicing
    private let favoriteRepository: any FavoriteRepository
    private let readingProgressController: MangaReadingProgressController
    private let persistenceMutationController = PersistenceMutationController()
    private let supplementaryLoadingController = DetailSupplementaryLoadingController()
    private var myListCancellable: AnyCancellable?

    // MARK: - Lifecycle

    init(
        malId: Int,
        service: MangaDetailServicing,
        favoriteRepository: any FavoriteRepository,
        readingProgressController: MangaReadingProgressController = MangaReadingProgressController()
    ) {
        self.malId = malId
        self.service = service
        self.favoriteRepository = favoriteRepository
        self.readingProgressController = readingProgressController
        self.synopsisTranslationViewModel = SynopsisTranslationViewModel(context: .mangaWork)
        connectToMyList()
    }

    // MARK: - State

    var detail: MangaDetailDTO? {
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

    var pictureItems: [MangaDetailPictureItem] {
        picturesState.value
    }

    var characterRoles: [MangaCharacterRoleDTO] {
        charactersState.value
    }

    var recommendationItems: [MangaRecommendationDTO] {
        recommendationsState.value
    }

    var isLoadingCharacters: Bool {
        charactersState.isLoading
    }

    var isLoadingPictures: Bool {
        picturesState.isLoading
    }

    var isLoadingRecommendations: Bool {
        recommendationsState.isLoading
    }

    var charactersFailure: FeatureLoadFailure? {
        charactersState.failure
    }

    var picturesFailure: FeatureLoadFailure? {
        picturesState.failure
    }

    var recommendationsFailure: FeatureLoadFailure? {
        recommendationsState.failure
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
            let response = try await service.fetchMangaDetail(malId: malId)
            let detail = response.data
            prepareSupplementaryLoading(resetOnFailure: existingDetail == nil)
            screenState = .loaded(detail)
            resetSynopsisTranslation()
            await loadSupplementaryContent(
                resetOnFailure: existingDetail == nil,
                loadingPrepared: true
            )
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

    private func loadSupplementaryContent(
        resetOnFailure: Bool,
        loadingPrepared: Bool = false
    ) async {
        let charactersResult = await loadCharacters(
            resetOnFailure: resetOnFailure,
            startsLoading: !loadingPrepared
        )
        switch charactersResult {
        case .cancelled:
            finishCancelledSupplementaryLoading(states: picturesState, recommendationsState)
            return
        case .failed(let failure) where failure.kind == .rateLimited:
            finishRateLimitedSupplementaryLoading(
                failure,
                resetOnFailure: resetOnFailure,
                states: picturesState,
                recommendationsState
            )
            return
        case .completed, .failed:
            break
        }

        let picturesResult = await loadPictures(
            resetOnFailure: resetOnFailure,
            startsLoading: !loadingPrepared
        )
        switch picturesResult {
        case .cancelled:
            recommendationsState.finishCancelledLoading()
            return
        case .failed(let failure) where failure.kind == .rateLimited:
            recommendationsState.finishLoading(
                with: failure,
                resetValueTo: resetOnFailure ? [] : nil
            )
            return
        case .completed, .failed:
            break
        }

        _ = await loadRecommendations(
            resetOnFailure: resetOnFailure,
            startsLoading: !loadingPrepared
        )
    }

    func reloadCharacters() async {
        _ = await loadCharacters(resetOnFailure: false)
    }

    func reloadPictures() async {
        _ = await loadPictures(resetOnFailure: false)
    }

    func reloadRecommendations() async {
        _ = await loadRecommendations(resetOnFailure: false)
    }

    // MARK: - Synopsis Translation

    func requestSynopsisTranslation(for manga: MangaDetailDTO) {
        synopsisTranslationViewModel.requestTranslation(
            for: synopsisDisplayText(for: manga),
            emptyFailureMessage: "沒有可翻譯的作品簡介。"
        )
    }

    private func resetSynopsisTranslation() {
        synopsisTranslationViewModel.reset()
    }

    // MARK: - Supplementary Content

    private func loadPictures(
        resetOnFailure: Bool,
        startsLoading: Bool = true
    ) async -> DetailSupplementaryLoadResult {
        await supplementaryLoadingController.load(
            state: picturesState,
            resetOnFailure: resetOnFailure,
            startsLoading: startsLoading,
            resetValue: [],
            fetch: {
                let response = try await service.fetchMangaPictures(malId: malId)
                return MangaDetailPictureMapping.items(from: response)
            }
        )
    }

    private func loadCharacters(
        resetOnFailure: Bool,
        startsLoading: Bool = true
    ) async -> DetailSupplementaryLoadResult {
        await supplementaryLoadingController.load(
            state: charactersState,
            resetOnFailure: resetOnFailure,
            startsLoading: startsLoading,
            resetValue: [],
            fetch: {
                try await service.fetchMangaCharacters(malId: malId).data
            }
        )
    }

    private func loadRecommendations(
        resetOnFailure: Bool,
        startsLoading: Bool = true
    ) async -> DetailSupplementaryLoadResult {
        await supplementaryLoadingController.load(
            state: recommendationsState,
            resetOnFailure: resetOnFailure,
            startsLoading: startsLoading,
            resetValue: [],
            fetch: {
                try await service.fetchMangaRecommendations(malId: malId).data
            }
        )
    }

    private func finishCancelledSupplementaryLoading<Value, OtherValue>(
        states firstState: DetailSupplementaryState<Value>,
        _ secondState: DetailSupplementaryState<OtherValue>
    ) {
        firstState.finishCancelledLoading()
        secondState.finishCancelledLoading()
    }

    private func finishRateLimitedSupplementaryLoading<Value, OtherValue>(
        _ failure: FeatureLoadFailure,
        resetOnFailure: Bool,
        states firstState: DetailSupplementaryState<Value>,
        _ secondState: DetailSupplementaryState<OtherValue>
    ) where Value: RangeReplaceableCollection, OtherValue: RangeReplaceableCollection {
        firstState.finishLoading(
            with: failure,
            resetValueTo: resetOnFailure ? Value() : nil
        )
        secondState.finishLoading(
            with: failure,
            resetValueTo: resetOnFailure ? OtherValue() : nil
        )
    }

    private func prepareSupplementaryLoading(resetOnFailure: Bool) {
        charactersState.beginLoading(resetOnFailure: resetOnFailure)
        picturesState.beginLoading(resetOnFailure: resetOnFailure)
        recommendationsState.beginLoading(resetOnFailure: resetOnFailure)
    }

    private func resetSupplementaryContent() {
        picturesState.reset(to: [])
        charactersState.reset(to: [])
        recommendationsState.reset(to: [])
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
                    item.malId == malId && item.mediaKind == .manga
                }
            }
    }

    func toggleFavorite(isFavorite: Bool) {
        performPersistenceMutation(
            failureMessage: "無法更新收藏，請稍後再試。",
            logPrefix: "Manga favorite update failed"
        ) {
            if isFavorite {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .manga,
                    draft: nil
                )
            } else if let detail {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .manga,
                    draft: favoriteDraft(for: detail)
                )
            }
        }
    }

    func updateReadingProgress(
        for item: MyListItemSnapshot,
        status: MangaReadingStatus,
        currentChapter: Int?,
        totalChapters: Int?
    ) {
        performPersistenceMutation(
            failureMessage: "無法更新閱讀進度，請稍後再試。",
            logPrefix: "Manga reading progress update failed"
        ) {
            try favoriteRepository.updateMangaReadingProgress(
                malId: item.malId,
                status: status,
                currentChapter: currentChapter,
                totalChapters: totalChapters
            )
        }
    }

    func dismissPersistenceMutationFailure() {
        guard case .failed = persistenceMutationState else { return }
        persistenceMutationState = .idle
    }

    private func performPersistenceMutation(
        failureMessage: String,
        logPrefix: String,
        operation: () throws -> Void
    ) {
        guard !persistenceMutationState.isProcessing else { return }
        persistenceMutationState = .processing
        persistenceMutationState = persistenceMutationController.perform(
            failureMessage: failureMessage,
            logPrefix: logPrefix,
            operation: operation
        )
    }

    func readingProgressEditorDraft(
        for item: MyListItemSnapshot,
        manga: MangaDetailDTO
    ) -> MangaReadingProgressEditorDraft {
        readingProgressController.editorDraft(for: item, manga: manga)
    }

    func incrementReadingProgress(
        for item: MyListItemSnapshot,
        manga: MangaDetailDTO
    ) {
        let update = readingProgressController.incrementUpdate(for: item, manga: manga)

        updateReadingProgress(
            for: item,
            status: update.status,
            currentChapter: update.currentChapter,
            totalChapters: update.totalChapters
        )
    }

    func decrementReadingProgress(
        for item: MyListItemSnapshot,
        manga: MangaDetailDTO
    ) {
        let update = readingProgressController.decrementUpdate(for: item, manga: manga)

        updateReadingProgress(
            for: item,
            status: update.status,
            currentChapter: update.currentChapter,
            totalChapters: update.totalChapters
        )
    }
}

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

    enum ActiveAlert: Equatable {
        case persistence(message: String)

        var title: String {
            "收藏與進度"
        }

        var message: String {
            switch self {
            case .persistence(let message):
                return message
            }
        }
    }

    @Published private(set) var screenState: ScreenState = .idle
    @Published private(set) var favoriteCollectionItem: MyListItemSnapshot?
    @Published private(set) var persistenceMutationState: PersistenceMutationState = .idle
    @Published private(set) var activeAlert: ActiveAlert?
    let picturesState = DetailSupplementaryState<[MangaDetailPictureItem]>(initialValue: [])
    let charactersState = DetailSupplementaryState<[MangaCharacterRoleDTO]>(initialValue: [])
    let recommendationsState = DetailSupplementaryState<[MangaRecommendationDTO]>(initialValue: [])
    let synopsisTranslationViewModel: SynopsisTranslationViewModel

    // MARK: - Dependencies

    private let malId: Int
    private let service: MangaDetailServicing
    private let favoriteRepository: any FavoriteRepository
    private let readingProgressController: MangaReadingProgressController
    private let requestLifecycleController: RequestScreenLifecycleController
    let parentTab: JikanAPIRequestScope
    private let persistenceMutationController = PersistenceMutationController()
    private let supplementaryLoadingController = DetailSupplementaryLoadingController()
    private var myListCancellable: AnyCancellable?
    private var shouldResumeSupplementaryLoading = false

    // MARK: - Lifecycle

    init(
        malId: Int,
        service: MangaDetailServicing,
        favoriteRepository: any FavoriteRepository,
        parentTab: JikanAPIRequestScope,
        requestLifecycleScope: RequestLifecycleScope,
        requestLifecycleController: any RequestLifecycleControlling,
        readingProgressController: MangaReadingProgressController = MangaReadingProgressController()
    ) {
        self.malId = malId
        self.service = service
        self.favoriteRepository = favoriteRepository
        self.parentTab = parentTab
        self.readingProgressController = readingProgressController
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleController
        )
        self.synopsisTranslationViewModel = SynopsisTranslationViewModel(context: .mangaWork)
        connectToMyList()
    }

    // MARK: - State

    var detail: MangaDetailDTO? {
        switch screenState {
        case let .refreshing(detail):
            return detail
        case let .loaded(detail):
            return detail
        case .idle:
            return nil
        case .loading:
            return nil
        case .error:
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

    func screenDidAppear() async {
        guard await requestLifecycleController.activate() else { return }

        if detail == nil {
            await load()
        } else if shouldResumeSupplementaryLoading {
            await resumeSupplementaryLoading()
        }
    }

    func screenDidDisappear() {
        requestLifecycleController.deactivate()
        dismissActiveAlert()
    }

    func refresh() {
        Task(priority: .userInitiated) { [weak self] in
            await self?.load(forceRefresh: true)
        }
    }

    func load(forceRefresh: Bool = false) async {
        guard let lifecycleToken = requestLifecycleController.activeLifecycleToken() else { return }
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
            guard requestLifecycleController.canApplyAsyncResult(for: lifecycleToken) else {
                restoreScreenStateAfterAsyncInvalidation(
                    existingDetail: existingDetail,
                    lifecycleToken: lifecycleToken
                )
                return
            }
            let detail = response.data
            prepareSupplementaryLoading(resetOnFailure: existingDetail == nil)
            screenState = .loaded(detail)
            resetSynopsisTranslation()
            shouldResumeSupplementaryLoading = true
            await loadSupplementaryContent(
                resetOnFailure: existingDetail == nil,
                loadingPrepared: true,
                lifecycleToken: lifecycleToken
            )
            shouldResumeSupplementaryLoading = Task.isCancelled
        } catch is CancellationError {
            guard requestLifecycleController.canApplyAsyncResult(for: lifecycleToken) else {
                restoreScreenStateAfterAsyncInvalidation(
                    existingDetail: existingDetail,
                    lifecycleToken: lifecycleToken
                )
                return
            }
            screenState = existingDetail.map(ScreenState.loaded) ?? .idle
            return
        } catch {
            guard requestLifecycleController.canApplyAsyncResult(for: lifecycleToken) else {
                restoreScreenStateAfterAsyncInvalidation(
                    existingDetail: existingDetail,
                    lifecycleToken: lifecycleToken
                )
                return
            }
            if let existingDetail, forceRefresh {
                screenState = .loaded(existingDetail)
            } else {
                screenState = .error(FeatureLoadFailure(error))
                resetSupplementaryContent()
            }
        }
    }

    private func restoreScreenStateAfterAsyncInvalidation(
        existingDetail: MangaDetailDTO?,
        lifecycleToken: RequestScreenLifecycleToken
    ) {
        guard requestLifecycleController.shouldRestoreAsyncState(for: lifecycleToken) else {
            return
        }
        screenState = existingDetail.map(ScreenState.loaded) ?? .idle
    }

    private func resumeSupplementaryLoading() async {
        guard let lifecycleToken = requestLifecycleController.activeLifecycleToken() else { return }
        shouldResumeSupplementaryLoading = true
        await loadSupplementaryContent(
            resetOnFailure: false,
            lifecycleToken: lifecycleToken
        )
        shouldResumeSupplementaryLoading = Task.isCancelled
    }

    private func loadSupplementaryContent(
        resetOnFailure: Bool,
        loadingPrepared: Bool = false,
        lifecycleToken: RequestScreenLifecycleToken
    ) async {
        let charactersResult = await loadCharacters(
            resetOnFailure: resetOnFailure,
            startsLoading: !loadingPrepared,
            lifecycleToken: lifecycleToken
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
        case .completed:
            break
        case .failed:
            break
        }

        let picturesResult = await loadPictures(
            resetOnFailure: resetOnFailure,
            startsLoading: !loadingPrepared,
            lifecycleToken: lifecycleToken
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
        case .completed:
            break
        case .failed:
            break
        }

        _ = await loadRecommendations(
            resetOnFailure: resetOnFailure,
            startsLoading: !loadingPrepared,
            lifecycleToken: lifecycleToken
        )
    }

    func reloadCharacters() async {
        guard let lifecycleToken = requestLifecycleController.activeLifecycleToken() else { return }
        _ = await loadCharacters(resetOnFailure: false, lifecycleToken: lifecycleToken)
    }

    func retryCharacters() {
        Task(priority: .userInitiated) { [weak self] in
            await self?.reloadCharacters()
        }
    }

    func reloadPictures() async {
        guard let lifecycleToken = requestLifecycleController.activeLifecycleToken() else { return }
        _ = await loadPictures(resetOnFailure: false, lifecycleToken: lifecycleToken)
    }

    func retryPictures() {
        Task(priority: .userInitiated) { [weak self] in
            await self?.reloadPictures()
        }
    }

    func reloadRecommendations() async {
        guard let lifecycleToken = requestLifecycleController.activeLifecycleToken() else { return }
        _ = await loadRecommendations(resetOnFailure: false, lifecycleToken: lifecycleToken)
    }

    func retryRecommendations() {
        Task(priority: .userInitiated) { [weak self] in
            await self?.reloadRecommendations()
        }
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
        startsLoading: Bool = true,
        lifecycleToken: RequestScreenLifecycleToken
    ) async -> DetailSupplementaryLoadResult {
        await supplementaryLoadingController.load(
            state: picturesState,
            resetOnFailure: resetOnFailure,
            startsLoading: startsLoading,
            resetValue: [],
            shouldApplyResult: { [requestLifecycleController] in
                requestLifecycleController.canApplyAsyncResult(for: lifecycleToken)
            },
            fetch: {
                let response = try await service.fetchMangaPictures(malId: malId)
                return MangaDetailPictureMapping.items(from: response)
            }
        )
    }

    private func loadCharacters(
        resetOnFailure: Bool,
        startsLoading: Bool = true,
        lifecycleToken: RequestScreenLifecycleToken
    ) async -> DetailSupplementaryLoadResult {
        await supplementaryLoadingController.load(
            state: charactersState,
            resetOnFailure: resetOnFailure,
            startsLoading: startsLoading,
            resetValue: [],
            shouldApplyResult: { [requestLifecycleController] in
                requestLifecycleController.canApplyAsyncResult(for: lifecycleToken)
            },
            fetch: {
                try await service.fetchMangaCharacters(malId: malId).data
            }
        )
    }

    private func loadRecommendations(
        resetOnFailure: Bool,
        startsLoading: Bool = true,
        lifecycleToken: RequestScreenLifecycleToken
    ) async -> DetailSupplementaryLoadResult {
        await supplementaryLoadingController.load(
            state: recommendationsState,
            resetOnFailure: resetOnFailure,
            startsLoading: startsLoading,
            resetValue: [],
            shouldApplyResult: { [requestLifecycleController] in
                requestLifecycleController.canApplyAsyncResult(for: lifecycleToken)
            },
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

    func presentPersistenceAlert(message: String) {
        guard requestLifecycleController.canPresentLifecycleBoundState else { return }
        activeAlert = .persistence(message: message)
    }

    func dismissActiveAlert() {
        activeAlert = nil
        dismissPersistenceMutationFailure()
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
        if let failureMessage = persistenceMutationState.failureMessage {
            presentPersistenceAlert(message: failureMessage)
        }
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

extension MangaDetailViewModel: RequestScreenLifecyclePresentable {}

//
//  MangaDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import Combine
import Foundation
import OSLog
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
    @Published private(set) var pictureItems: [MangaDetailPictureItem] = []
    @Published private(set) var characterRoles: [MangaCharacterRoleDTO] = []
    @Published private(set) var recommendationItems: [MangaRecommendationDTO] = []
    @Published private(set) var isLoadingCharacters = false
    @Published private(set) var isLoadingPictures = false
    @Published private(set) var isLoadingRecommendations = false
    @Published private(set) var charactersFailure: FeatureLoadFailure?
    @Published private(set) var picturesFailure: FeatureLoadFailure?
    @Published private(set) var recommendationsFailure: FeatureLoadFailure?
    @Published private(set) var favoriteCollectionItem: MyListCollectionItem?
    let synopsisTranslationViewModel: SynopsisTranslationViewModel

    // MARK: - Dependencies

    private let malId: Int
    private let service: MangaDetailServicing
    private let favoriteRepository: any FavoriteRepository
    private let readingProgressController: MangaReadingProgressController
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

    func requestSynopsisTranslation(for manga: MangaDetailDTO) {
        synopsisTranslationViewModel.requestTranslation(
            for: synopsisDisplayText(for: manga),
            emptyFailureMessage: "沒有可翻譯的作品簡介。"
        )
    }

    private func resetSynopsisTranslationIfNeeded(for manga: MangaDetailDTO) {
        synopsisTranslationViewModel.reset()
    }

    // MARK: - Supplementary Content

    private func loadPictures(resetOnFailure: Bool) async {
        isLoadingPictures = true
        if resetOnFailure {
            picturesFailure = nil
        }
        defer { isLoadingPictures = false }

        do {
            let resolvedPictures = try await service.fetchMangaPictures(malId: malId)
            pictureItems = MangaDetailPictureMapping.items(from: resolvedPictures)
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
            let resolvedCharacters = try await service.fetchMangaCharacters(malId: malId)
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
            let resolvedRecommendations = try await service.fetchMangaRecommendations(malId: malId)
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
                    item.malId == malId && item.mediaKind == .manga
                }
            }
    }

    func toggleFavorite(isFavorite: Bool) {
        do {
            if isFavorite {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .manga,
                    makeItem: nil
                )
            } else if let detail {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .manga,
                    makeItem: { self.favoriteItem(for: detail) }
                )
            }
        } catch {
            AppLogger.persistence.error("Manga favorite update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func updateReadingProgress(
        for item: MyListCollectionItem,
        status: MangaReadingStatus,
        currentChapter: Int?,
        totalChapters: Int?
    ) {
        item.updateMangaReadingProgress(
            status: status,
            currentChapter: currentChapter,
            totalChapters: totalChapters
        )

        do {
            try favoriteRepository.saveChanges()
        } catch {
            AppLogger.persistence.error("Manga reading progress update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func readingProgressEditorDraft(
        for item: MyListCollectionItem,
        manga: MangaDetailDTO
    ) -> MangaReadingProgressEditorDraft {
        readingProgressController.editorDraft(for: item, manga: manga)
    }

    func incrementReadingProgress(
        for item: MyListCollectionItem,
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
        for item: MyListCollectionItem,
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

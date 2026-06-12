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

    private let malId: Int
    private let service: MangaDetailServicing
    private let favoriteRepository: any FavoriteRepository

    init(
        malId: Int,
        service: MangaDetailServicing,
        favoriteRepository: any FavoriteRepository
    ) {
        self.malId = malId
        self.service = service
        self.favoriteRepository = favoriteRepository
    }

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
            screenState = .loaded(response.data)
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
        await loadPictures(resetOnFailure: resetOnFailure)
        await loadCharacters(resetOnFailure: resetOnFailure)
        await loadRecommendations(resetOnFailure: resetOnFailure)
    }

    private func loadPictures(resetOnFailure: Bool) async {
        do {
            let resolvedPictures = try await service.fetchMangaPictures(malId: malId)
            pictureItems = MangaDetailPictureMapping.items(from: resolvedPictures)
        } catch is CancellationError {
        } catch {
            if resetOnFailure {
                pictureItems = []
            }
        }
    }

    private func loadCharacters(resetOnFailure: Bool) async {
        do {
            let resolvedCharacters = try await service.fetchMangaCharacters(malId: malId)
            characterRoles = resolvedCharacters.data
        } catch is CancellationError {
        } catch {
            if resetOnFailure {
                characterRoles = []
            }
        }
    }

    private func loadRecommendations(resetOnFailure: Bool) async {
        do {
            let resolvedRecommendations = try await service.fetchMangaRecommendations(malId: malId)
            recommendationItems = resolvedRecommendations.data
        } catch is CancellationError {
        } catch {
            if resetOnFailure {
                recommendationItems = []
            }
        }
    }

    private func resetSupplementaryContent() {
        pictureItems = []
        characterRoles = []
        recommendationItems = []
    }

    var isFavoriteActionEnabled: Bool {
        detail != nil
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
        MangaReadingProgressEditorDraft(
            item: item,
            totalChapters: totalChapters(for: manga)
        )
    }

    func incrementReadingProgress(
        for item: MyListCollectionItem,
        manga: MangaDetailDTO
    ) {
        let resolvedTotalChapters = totalChapters(for: manga)
        let nextChapter = min(
            (item.currentChapter ?? 0) + 1,
            resolvedTotalChapters ?? Int.max
        )
        let nextStatus: MangaReadingStatus
        if let resolvedTotalChapters, nextChapter >= resolvedTotalChapters {
            nextStatus = .completed
        } else {
            nextStatus = .reading
        }

        updateReadingProgress(
            for: item,
            status: nextStatus,
            currentChapter: nextChapter,
            totalChapters: resolvedTotalChapters
        )
    }

    func decrementReadingProgress(
        for item: MyListCollectionItem,
        manga: MangaDetailDTO
    ) {
        let resolvedTotalChapters = totalChapters(for: manga)
        let nextChapter = max((item.currentChapter ?? 0) - 1, 0)
        let nextStatus: MangaReadingStatus = nextChapter > 0 ? .reading : .planned

        updateReadingProgress(
            for: item,
            status: nextStatus,
            currentChapter: nextChapter,
            totalChapters: resolvedTotalChapters
        )
    }

    private func totalChapters(for manga: MangaDetailDTO) -> Int? {
        guard let chapters = manga.chapters, chapters > 0 else { return nil }
        return chapters
    }
}

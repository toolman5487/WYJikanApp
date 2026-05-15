//
//  AnimeDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Combine
import Foundation
import OSLog
import SwiftData

@MainActor
final class AnimeDetailViewModel: ObservableObject {
    enum ScreenState {
        case idle
        case loading
        case refreshing(AnimeDetailDTO)
        case loaded(AnimeDetailDTO)
        case error(String)
    }

    @Published private(set) var screenState: ScreenState = .idle
    @Published private(set) var pictureItems: [AnimeDetailPictureItem] = []
    @Published private(set) var characterRoles: [AnimeCharacterRoleDTO] = []
    @Published private(set) var recommendationItems: [AnimeRecommendationDTO] = []

    private let malId: Int
    private let service: AnimeDetailServicing
    private let favoriteRepository: any FavoriteRepository

    init(
        malId: Int,
        service: AnimeDetailServicing = AnimeDetailService(),
        favoriteRepository: any FavoriteRepository = SwiftDataFavoriteRepository.shared
    ) {
        self.malId = malId
        self.service = service
        self.favoriteRepository = favoriteRepository
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
                screenState = .error(error.localizedDescription)
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
            let resolvedPictures = try await service.fetchAnimePictures(malId: malId)
            pictureItems = AnimeDetailPictureMapping.items(from: resolvedPictures)
        } catch is CancellationError {
        } catch {
            if resetOnFailure {
                pictureItems = []
            }
        }
    }

    private func loadCharacters(resetOnFailure: Bool) async {
        do {
            let resolvedCharacters = try await service.fetchAnimeCharacters(malId: malId)
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
            let resolvedRecommendations = try await service.fetchAnimeRecommendations(malId: malId)
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

    func toggleFavorite(
        isFavorite: Bool,
        modelContext: ModelContext
    ) {
        do {
            if isFavorite {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .anime,
                    modelContext: modelContext,
                    makeItem: nil
                )
            } else if let detail {
                _ = try favoriteRepository.toggleFavorite(
                    malId: malId,
                    mediaKind: .anime,
                    modelContext: modelContext,
                    makeItem: { self.favoriteItem(for: detail) }
                )
            }
        } catch {
            AppLogger.persistence.error("Anime favorite update failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

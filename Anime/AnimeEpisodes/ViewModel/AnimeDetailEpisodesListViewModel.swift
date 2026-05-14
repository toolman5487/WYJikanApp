//
//  AnimeDetailEpisodesListViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Combine
import Foundation
import OSLog

@MainActor
final class AnimeDetailEpisodesListViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case empty
        case content
        case error(String)
    }

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var episodes: [AnimeEpisodeDTO] = []
    @Published private(set) var hasNextPage = false
    @Published private(set) var isLoadingMore = false

    private let malId: Int
    private let service: any AnimeDetailServicing
    private var currentPage = 0
    private var hasLoaded = false

    init(
        malId: Int,
        service: any AnimeDetailServicing = AnimeDetailService()
    ) {
        self.malId = malId
        self.service = service
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await loadFirstPage()
    }

    func loadMore() async {
        guard hasLoaded, hasNextPage, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response = try await service.fetchAnimeEpisodes(malId: malId, page: currentPage + 1)
            currentPage += 1
            hasNextPage = response.pagination?.hasNextPage == true
            episodes.append(contentsOf: response.data)
        } catch is CancellationError {
        } catch {
            AppLogger.network.error(
                "Anime episodes load-more failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func loadFirstPage() async {
        screenState = .loading

        do {
            let response = try await service.fetchAnimeEpisodes(malId: malId, page: 1)
            hasLoaded = true
            currentPage = 1
            hasNextPage = response.pagination?.hasNextPage == true
            episodes = response.data
            screenState = episodes.isEmpty ? .empty : .content
        } catch is CancellationError {
        } catch {
            screenState = .error(error.localizedDescription)
        }
    }
}

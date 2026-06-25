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
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden
    @Published private(set) var episodes: [AnimeEpisodeDTO] = []
    @Published private(set) var episodeRows: [AnimeDetailEpisodeRowPresentation] = []
    @Published private(set) var expandedEpisodeIDs: Set<Int> = []
    @Published private(set) var episodeDetailStates: [Int: AnimeDetailEpisodeDetailPresentation] = [:]

    private let malId: Int
    private let service: any AnimeDetailServicing
    private let rowPresenter: AnimeDetailEpisodeRowPresenter
    private let requestLifecycleController: RequestScreenLifecycleController
    let parentTab: JikanAPIRequestScope
    private var currentPage = 0
    private var hasNextPage = false
    private var hasLoaded = false
    private var isLoadingMore = false
    private var episodesByRowID: [Int: AnimeEpisodeDTO] = [:]

    init(
        malId: Int,
        service: any AnimeDetailServicing,
        parentTab: JikanAPIRequestScope,
        requestLifecycleScope: RequestLifecycleScope,
        requestLifecycleController: any RequestLifecycleControlling,
        rowPresenter: AnimeDetailEpisodeRowPresenter = AnimeDetailEpisodeRowPresenter()
    ) {
        self.malId = malId
        self.service = service
        self.parentTab = parentTab
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleController
        )
        self.rowPresenter = rowPresenter
    }

    func screenDidAppear() async {
        guard await requestLifecycleController.activate() else { return }
        guard !hasLoaded else { return }
        await loadFirstPage()
    }

    func screenDidDisappear() {
        requestLifecycleController.deactivate()
    }

    func loadMore() async {
        await loadMorePage()
    }

    func retryLoadMore() async {
        guard case .error = loadMoreState else { return }
        await loadMorePage()
    }

    func toggleEpisodeDetail(for rowID: Int) async {
        guard let episode = episodesByRowID[rowID],
              let episodeNumber = episode.malId else {
            return
        }

        if expandedEpisodeIDs.contains(episodeNumber) {
            expandedEpisodeIDs.remove(episodeNumber)
            rebuildEpisodeRows()
            return
        }

        expandedEpisodeIDs.insert(episodeNumber)
        rebuildEpisodeRows()
        guard episodeDetailStates[episodeNumber] == nil else { return }

        episodeDetailStates[episodeNumber] = .loading(
            rowPresenter.expandedPresentation(for: episode)
        )
        rebuildEpisodeRows()

        do {
            let response = try await service.fetchAnimeEpisodeDetail(
                malId: malId,
                episodeNumber: episodeNumber
            )
            let detailEpisode = response.data.mergedWithFallback(episode)
            episodeDetailStates[episodeNumber] = .content(
                rowPresenter.expandedPresentation(for: detailEpisode)
            )
            rebuildEpisodeRows()
        } catch is CancellationError {
            episodeDetailStates[episodeNumber] = .content(
                rowPresenter.expandedPresentation(for: episode)
            )
            rebuildEpisodeRows()
        } catch {
            episodeDetailStates[episodeNumber] = .error(
                FeatureLoadFailure(error),
                rowPresenter.expandedPresentation(for: episode)
            )
            rebuildEpisodeRows()
        }
    }

    private func loadFirstPage() async {
        resetPagination()
        screenState = .loading

        do {
            let response = try await service.fetchAnimeEpisodes(malId: malId, page: 1)
            hasLoaded = true
            currentPage = 1
            hasNextPage = resolvedHasNextPage(
                from: response.pagination,
                responseData: response.data
            )
            episodes = response.data
            refreshEpisodeCaches()
            rebuildEpisodeRows()
            screenState = episodes.isEmpty ? .empty : .content
            loadMoreState = resolvedLoadMoreState()
        } catch is CancellationError {
        } catch {
            screenState = .error(FeatureLoadFailure(error))
            loadMoreState = .hidden
        }
    }

    private func loadMorePage() async {
        guard hasLoaded, hasNextPage, !isLoadingMore else { return }

        isLoadingMore = true
        loadMoreState = .loading

        do {
            let response = try await service.fetchAnimeEpisodes(malId: malId, page: currentPage + 1)
            currentPage += 1
            hasNextPage = resolvedHasNextPage(
                from: response.pagination,
                responseData: response.data
            )
            episodes.append(contentsOf: response.data)
            refreshEpisodeCaches()
            rebuildEpisodeRows()
            isLoadingMore = false
            loadMoreState = resolvedLoadMoreState()
        } catch is CancellationError {
            isLoadingMore = false
            loadMoreState = resolvedLoadMoreState()
        } catch {
            AppLogger.network.error(
                "Anime episodes load-more failed: \(error.localizedDescription, privacy: .public)"
            )
            isLoadingMore = false
            loadMoreState = .error(FeatureLoadFailure.loadMore(message: "載入更多集數失敗"))
        }
    }

    private func resetPagination() {
        currentPage = 0
        hasNextPage = false
        isLoadingMore = false
        loadMoreState = .hidden
    }

    private func resolvedLoadMoreState() -> LoadMoreState {
        if isLoadingMore {
            return .loading
        }
        if case .error(let failure) = loadMoreState {
            return .error(failure)
        }
        return hasNextPage ? .available : .hidden
    }

    private func resolvedHasNextPage(
        from pagination: AnimeEpisodesPaginationDTO?,
        responseData: [AnimeEpisodeDTO]
    ) -> Bool {
        switch (pagination?.hasNextPage, pagination?.lastVisiblePage) {
        case (.some(let hasNextPage), _):
            return hasNextPage
        case (.none, .some(let lastVisiblePage)):
            return currentPage < lastVisiblePage
        case (.none, .none):
            return !responseData.isEmpty
        }
    }

    private func refreshEpisodeCaches() {
        episodesByRowID = Dictionary(uniqueKeysWithValues: episodes.map { ($0.id, $0) })
    }

    private func rebuildEpisodeRows() {
        episodeRows = episodes.map { episode in
            rowPresenter.rowPresentation(
                for: episode,
                expandedEpisodeIDs: expandedEpisodeIDs,
                episodeDetailStates: episodeDetailStates
            )
        }
    }
}

extension AnimeDetailEpisodesListViewModel: RequestScreenLifecyclePresentable {}

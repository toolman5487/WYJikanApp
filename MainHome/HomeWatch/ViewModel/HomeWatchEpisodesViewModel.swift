//
//  HomeWatchEpisodesViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Combine
import Foundation

// MARK: - HomeWatchEpisodesViewModel

@MainActor
final class HomeWatchEpisodesViewModel: ObservableObject {

    // MARK: - Properties

    private static let maxCards = 10

    @Published private(set) var screenState: HomeWatchSectionState<HomeWatchEpisodeItem> = .loading

    private let service: HomeWatchServicing
    private let sectionLoader = HomeFeedSectionLoader()

    // MARK: - Lifecycle

    init(service: HomeWatchServicing) {
        self.service = service
    }

    deinit {
        sectionLoader.cancel()
    }

    // MARK: - Derived State

    var items: [HomeWatchEpisodeItem] {
        screenState.items
    }

    // MARK: - Public Methods

    func loadIfNeeded() {
        sectionLoader.loadIfNeeded(isContentEmpty: items.isEmpty) {
            load()
        }
    }

    func refresh() async {
        await sectionLoader.refresh(hasContent: screenState.hasContent) { [weak self] forceRefresh, showsLoadingState in
            await self?.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
    }

    func load() {
        sectionLoader.load { [weak self] forceRefresh, showsLoadingState in
            await self?.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
    }

    // MARK: - Private Methods

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        defer {
            sectionLoader.markIdle()
        }

        if showsLoadingState {
            screenState = .loading
        }

        do {
            let response = try await service.fetchLatestEpisodes(forceRefresh: forceRefresh)
            let items = HomeWatchPresentationBuilder.episodeItems(
                from: response,
                limit: Self.maxCards
            )

            screenState = items.isEmpty ? .empty : .content(items)
        } catch is CancellationError {
            return
        } catch {
            if forceRefresh, previousState.hasContent {
                screenState = previousState
            } else {
                screenState = .error(FeatureLoadFailure(error))
            }
        }
    }
}

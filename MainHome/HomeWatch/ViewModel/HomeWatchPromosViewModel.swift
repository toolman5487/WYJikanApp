//
//  HomeWatchPromosViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Combine
import Foundation

@MainActor
final class HomeWatchPromosViewModel: ObservableObject {
    private static let maxCards = 8

    @Published private(set) var screenState: HomeWatchSectionState<HomeWatchPromoItem> = .loading

    private let service: HomeWatchServicing
    private let sectionLoader = HomeFeedSectionLoader()

    init(service: HomeWatchServicing) {
        self.service = service
    }

    deinit {
        sectionLoader.cancel()
    }

    var items: [HomeWatchPromoItem] {
        screenState.items
    }

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

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        defer {
            sectionLoader.markIdle()
        }

        if showsLoadingState {
            screenState = .loading
        }

        do {
            let response = try await service.fetchLatestPromos(forceRefresh: forceRefresh)
            let items = HomeWatchPresentationBuilder.promoItems(
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

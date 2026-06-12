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
    private enum LoadState {
        case idle
        case loading(Task<Void, Never>)

        nonisolated var task: Task<Void, Never>? {
            switch self {
            case .idle:
                return nil
            case .loading(let task):
                return task
            }
        }

        nonisolated var isLoading: Bool {
            switch self {
            case .idle:
                return false
            case .loading:
                return true
            }
        }
    }

    private static let maxCards = 8

    @Published private(set) var screenState: HomeWatchSectionState<HomeWatchPromoItem> = .loading

    private let service: HomeWatchServicing
    private var loadState: LoadState = .idle

    init(service: HomeWatchServicing) {
        self.service = service
    }

    deinit {
        loadState.task?.cancel()
    }

    var items: [HomeWatchPromoItem] {
        screenState.items
    }

    func loadIfNeeded() {
        guard items.isEmpty, !loadState.isLoading else { return }
        load()
    }

    func refresh() async {
        if let task = loadState.task {
            await task.value
            return
        }

        let task = startLoad(forceRefresh: true, showsLoadingState: !screenState.hasContent)
        await task.value
    }

    func load() {
        guard !loadState.isLoading else { return }
        _ = startLoad(forceRefresh: false, showsLoadingState: true)
    }

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        defer {
            loadState = .idle
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
                screenState = .error(error.userFacingMessage)
            }
        }
    }

    private func startLoad(forceRefresh: Bool, showsLoadingState: Bool) -> Task<Void, Never> {
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
        loadState = .loading(task)
        return task
    }
}

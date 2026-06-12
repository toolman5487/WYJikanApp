//
//  HomeTrendingViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Combine
import Foundation

enum HomeTrendingAnimeScreenState: Equatable {
    case loading
    case error(FeatureLoadFailure)
    case empty
    case content([HomeTrendingAnimeCardItem])

    var items: [HomeTrendingAnimeCardItem] {
        switch self {
        case .content(let items):
            return items
        case .loading, .error, .empty:
            return []
        }
    }

    var hasContent: Bool {
        switch self {
        case .content:
            return true
        case .loading, .error, .empty:
            return false
        }
    }
}

@MainActor
final class HomeTrendingAnimeViewModel: ObservableObject {
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

    private static let maxCards = 10

    @Published private(set) var screenState: HomeTrendingAnimeScreenState = .loading

    private let service: MainHomeServicing
    private var loadState: LoadState = .idle

    init(service: MainHomeServicing) {
        self.service = service
    }

    deinit {
        loadState.task?.cancel()
    }

    var items: [HomeTrendingAnimeCardItem] {
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
            let response = try await service.fetchTopAnime(
                limit: Self.maxCards,
                forceRefresh: forceRefresh
            )
            let mapped: [HomeTrendingAnimeCardItem] = response.data.compactMap { dto -> HomeTrendingAnimeCardItem? in
                guard let urlString =
                    dto.images?.webp?.imageUrl ??
                    dto.images?.jpg?.imageUrl ??
                    dto.images?.webp?.largeImageUrl ??
                    dto.images?.jpg?.largeImageUrl,
                    let url = URL(string: urlString) else { return nil }

                return HomeTrendingAnimeCardItem(
                    id: dto.malId,
                    title: Self.displayTitle(
                        japanese: dto.titleJapanese,
                        english: dto.titleEnglish,
                        fallback: dto.title
                    ),
                    type: dto.type,
                    score: dto.score,
                    rank: dto.rank,
                    imageURL: url
                )
            }

            screenState = mapped.isEmpty ? .empty : .content(mapped)
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

    private func startLoad(forceRefresh: Bool, showsLoadingState: Bool) -> Task<Void, Never> {
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
        loadState = .loading(task)
        return task
    }

    private static func displayTitle(japanese: String?, english: String?, fallback: String?) -> String {
        switch [
            japanese?.trimmingCharacters(in: .whitespacesAndNewlines),
            english?.trimmingCharacters(in: .whitespacesAndNewlines),
            fallback?.trimmingCharacters(in: .whitespacesAndNewlines)
        ].compactMap({ $0 }).first(where: { !$0.isEmpty }) {
        case .some(let title):
            return title
        case .none:
            return "未命名作品"
        }
    }
}

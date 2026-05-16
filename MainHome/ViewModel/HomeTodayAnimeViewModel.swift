//
//  HomeTodayAnimeViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Combine
import Foundation

enum HomeTodayAnimeScreenState: Equatable {
    case loading
    case error(String)
    case empty
    case content([HomeTodayAnimeCardItem])
}

@MainActor
final class HomeTodayAnimeViewModel: ObservableObject {
    private static let maxCards = 10
    private static let scheduleFetchLimit = 25

    @Published private(set) var screenState: HomeTodayAnimeScreenState = .loading

    private let service: MainHomeServicing
    private var loadTask: Task<Void, Never>?
    private var isLoading = false

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    deinit {
        loadTask?.cancel()
    }

    var items: [HomeTodayAnimeCardItem] {
        switch screenState {
        case .content(let items):
            return items
        case .loading, .error, .empty:
            return []
        }
    }

    func loadIfNeeded() {
        guard items.isEmpty, !isLoading else { return }
        load()
    }

    func refresh() async {
        if let loadTask, isLoading {
            await loadTask.value
            return
        }

        let task = startLoad(forceRefresh: true, showsLoadingState: !hasContent)
        await task.value
    }

    func load() {
        guard !isLoading else { return }
        _ = startLoad(forceRefresh: false, showsLoadingState: true)
    }

    private var hasContent: Bool {
        switch screenState {
        case .content:
            return true
        case .loading, .error, .empty:
            return false
        }
    }

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        isLoading = true
        defer {
            isLoading = false
            loadTask = nil
        }

        if showsLoadingState {
            screenState = .loading
        }

        do {
            let response = try await service.fetchTodayAnime(
                limit: Self.scheduleFetchLimit,
                forceRefresh: forceRefresh
            )
            let mapped: [HomeTodayAnimeCardItem] = response.data.compactMap { dto -> HomeTodayAnimeCardItem? in
                guard let urlString =
                    dto.images?.jpg?.largeImageUrl ??
                    dto.images?.webp?.largeImageUrl ??
                    dto.images?.jpg?.imageUrl ??
                    dto.images?.webp?.imageUrl,
                    let url = URL(string: urlString) else { return nil }

                return HomeTodayAnimeCardItem(
                    id: dto.malId,
                    title: Self.displayTitle(
                        japanese: dto.titleJapanese,
                        english: dto.titleEnglish,
                        fallback: dto.title
                    ),
                    type: dto.type,
                    score: dto.score,
                    imageURL: url
                )
            }

            var seenIDs = Set<Int>()
            let uniqueInOrder = mapped.filter { seenIDs.insert($0.id).inserted }
            let items = Array(uniqueInOrder.prefix(Self.maxCards))
            screenState = items.isEmpty ? .empty : .content(items)
        } catch is CancellationError {
            return
        } catch {
            if forceRefresh, case .content = previousState {
                screenState = previousState
            } else {
                screenState = .error(error.localizedDescription)
            }
        }
    }

    private func startLoad(forceRefresh: Bool, showsLoadingState: Bool) -> Task<Void, Never> {
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
        loadTask = task
        return task
    }

    private static func displayTitle(japanese: String?, english: String?, fallback: String?) -> String {
        if let japanese, !japanese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return japanese
        }
        if let english, !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return english
        }
        if let fallback, !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fallback
        }
        return "未命名作品"
    }
}

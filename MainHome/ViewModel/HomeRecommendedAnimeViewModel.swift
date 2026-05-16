//
//  HomeRecommendedAnimeViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/27.
//

import Combine
import Foundation

enum HomeRecommendedAnimeScreenState: Equatable {
    case loading
    case error(String)
    case empty
    case content([HomeRecommendedAnimeCardItem])
}

@MainActor
final class HomeRecommendedAnimeViewModel: ObservableObject {
    private static let initialVisibleCards = 9
    private static let loadMoreStep = 9
    private static let maxCards = 30
    private static let titleEnrichmentDelayNanoseconds: UInt64 = 350_000_000
    private static var titleCache: [Int: String] = [:]

    @Published private(set) var screenState: HomeRecommendedAnimeScreenState = .loading
    @Published private(set) var visibleCount: Int = 9

    private let service: MainHomeServicing
    private var loadTask: Task<Void, Never>?
    private var titleEnrichmentTask: Task<Void, Never>?
    private var isLoading = false

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    deinit {
        loadTask?.cancel()
        titleEnrichmentTask?.cancel()
    }

    private var allItems: [HomeRecommendedAnimeCardItem] {
        switch screenState {
        case .content(let items):
            return items
        case .loading, .error, .empty:
            return []
        }
    }

    var displayedItems: [HomeRecommendedAnimeCardItem] {
        Array(allItems.prefix(visibleCount))
    }

    var canLoadMore: Bool {
        visibleCount < allItems.count
    }

    func loadIfNeeded() {
        guard allItems.isEmpty, !isLoading else { return }
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

    func loadMore() {
        visibleCount = min(visibleCount + Self.loadMoreStep, allItems.count)
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
        let previousVisibleCount = visibleCount
        titleEnrichmentTask?.cancel()
        isLoading = true
        defer {
            isLoading = false
            loadTask = nil
        }

        if showsLoadingState {
            screenState = .loading
            visibleCount = Self.initialVisibleCards
        }

        do {
            let response = try await service.fetchRecommendedAnime(
                limit: Self.maxCards,
                forceRefresh: forceRefresh
            )
            let mapped: [HomeRecommendedAnimeCardItem] = response.data.compactMap { dto in
                guard dto.entry.count >= 2 else { return nil }
                let source = dto.entry[0]
                let recommended = dto.entry[1]
                guard let urlString =
                    recommended.images?.webp?.largeImageUrl ??
                    recommended.images?.jpg?.largeImageUrl ??
                    recommended.images?.webp?.imageUrl ??
                    recommended.images?.jpg?.imageUrl,
                    let url = URL(string: urlString)
                else { return nil }

                return HomeRecommendedAnimeCardItem(
                    id: dto.id,
                    sourceTitle: source.title?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "原作",
                    recommendedTitle: Self.titleCache[recommended.malId] ??
                        recommended.title?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ??
                        "推薦作品",
                    username: dto.user?.username?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty,
                    detailMalId: recommended.malId,
                    imageURL: url
                )
            }

            var seenRecommendationIDs = Set<String>()
            let items = mapped.filter { seenRecommendationIDs.insert($0.id).inserted }
            visibleCount = resolvedVisibleCount(
                itemCount: items.count,
                previousVisibleCount: previousVisibleCount,
                preservesExpandedState: forceRefresh && hasContentState(previousState)
            )
            screenState = items.isEmpty ? .empty : .content(items)
            startTitleEnrichmentIfNeeded()
        } catch is CancellationError {
            return
        } catch {
            if forceRefresh, hasContentState(previousState) {
                screenState = previousState
                visibleCount = previousVisibleCount
                startTitleEnrichmentIfNeeded()
            } else {
                screenState = .error(error.localizedDescription)
            }
        }
    }

    private func startTitleEnrichmentIfNeeded() {
        titleEnrichmentTask?.cancel()
        let uncachedIDs = allItems.compactMap { item in
            Self.titleCache[item.detailMalId] == nil ? item.detailMalId : nil
        }
        guard !uncachedIDs.isEmpty else { return }

        titleEnrichmentTask = Task { [weak self] in
            guard let self else { return }
            for id in uncachedIDs {
                if Task.isCancelled { return }
                do {
                    let response = try await self.service.fetchAnimeDetail(
                        malId: id,
                        forceRefresh: false
                    )
                    let anime = response.data
                    let title = Self.preferredTitle(
                        japanese: anime.titleJapanese,
                        english: anime.titleEnglish,
                        fallback: anime.title
                    )
                    Self.titleCache[id] = title
                    self.replaceRecommendedTitle(for: id, with: title)
                    try? await Task.sleep(nanoseconds: Self.titleEnrichmentDelayNanoseconds)
                } catch {
                    continue
                }
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

    private func hasContentState(_ state: HomeRecommendedAnimeScreenState) -> Bool {
        switch state {
        case .content:
            return true
        case .loading, .error, .empty:
            return false
        }
    }

    private func resolvedVisibleCount(
        itemCount: Int,
        previousVisibleCount: Int,
        preservesExpandedState: Bool
    ) -> Int {
        guard itemCount > 0 else { return 0 }

        if preservesExpandedState {
            return min(max(previousVisibleCount, Self.initialVisibleCards), itemCount)
        }

        return min(Self.initialVisibleCards, itemCount)
    }

    private func replaceRecommendedTitle(for malId: Int, with title: String) {
        let updatedItems = allItems.map { item in
            guard item.detailMalId == malId else { return item }
            return HomeRecommendedAnimeCardItem(
                id: item.id,
                sourceTitle: item.sourceTitle,
                recommendedTitle: title,
                username: item.username,
                detailMalId: item.detailMalId,
                imageURL: item.imageURL
            )
        }
        screenState = updatedItems.isEmpty ? .empty : .content(updatedItems)
    }


    private nonisolated static func preferredTitle(japanese: String?, english: String?, fallback: String?) -> String {
        if let japanese, !japanese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return japanese
        }
        if let english, !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return english
        }
        if let fallback, !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fallback
        }
        return "推薦作品"
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

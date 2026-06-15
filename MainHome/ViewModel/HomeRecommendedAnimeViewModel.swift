//
//  HomeRecommendedAnimeViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/27.
//

import Combine
import Foundation

typealias HomeRecommendedAnimeScreenState = LoadableContentState<[HomeRecommendedAnimeCardItem]>

@MainActor
final class HomeRecommendedAnimeViewModel: ObservableObject {
    private static let initialVisibleCards = 9
    private static let loadMoreStep = 9
    private static let maxCards = 30
    private static let maxTitleEnrichmentsPerPass = 3
    private static let titleEnrichmentDelayNanoseconds: UInt64 = 1_000_000_000
    private static let titleCacheLimit = 100
    private static var titleCache: [Int: String] = [:]
    private static var titleCacheOrder: [Int] = []

    @Published private(set) var screenState: HomeRecommendedAnimeScreenState = .loading
    @Published private(set) var visibleCount: Int = 9

    private let service: MainHomeServicing
    private let animeDetailService: AnimeDetailServicing
    private let sectionLoader = HomeFeedSectionLoader()
    private var titleEnrichmentTask: Task<Void, Never>?

    init(service: MainHomeServicing, animeDetailService: AnimeDetailServicing) {
        self.service = service
        self.animeDetailService = animeDetailService
    }

    deinit {
        sectionLoader.cancel()
        titleEnrichmentTask?.cancel()
    }

    private var allItems: [HomeRecommendedAnimeCardItem] {
        screenState.items
    }

    var displayedItems: [HomeRecommendedAnimeCardItem] {
        Array(allItems.prefix(visibleCount))
    }

    var canLoadMore: Bool {
        visibleCount < allItems.count
    }

    func loadIfNeeded() {
        sectionLoader.loadIfNeeded(isContentEmpty: allItems.isEmpty) {
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

    func loadMore() {
        let previousCount = visibleCount
        visibleCount = min(visibleCount + Self.loadMoreStep, allItems.count)
        guard visibleCount > previousCount else { return }
        startTitleEnrichmentIfNeeded()
    }

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        let previousVisibleCount = visibleCount
        titleEnrichmentTask?.cancel()
        defer {
            sectionLoader.markIdle()
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
                guard let url = JikanImageURLResolver.url(
                    from: recommended.images,
                    tier: .card
                ) else { return nil }

                return HomeRecommendedAnimeCardItem(
                    id: dto.id,
                    sourceTitle: source.title?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "原作",
                    recommendedTitle: Self.cachedTitle(for: recommended.malId) ??
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
                preservesExpandedState: forceRefresh && previousState.hasContent
            )
            screenState = items.isEmpty ? .empty : .content(items)
            startTitleEnrichmentIfNeeded()
        } catch is CancellationError {
            return
        } catch {
            if forceRefresh, previousState.hasContent {
                screenState = previousState
                visibleCount = previousVisibleCount
                startTitleEnrichmentIfNeeded()
            } else {
                screenState = .error(FeatureLoadFailure(error))
            }
        }
    }

    private func startTitleEnrichmentIfNeeded() {
        titleEnrichmentTask?.cancel()
        let uncachedIDs = displayedItems.compactMap { item in
            Self.cachedTitle(for: item.detailMalId) == nil ? item.detailMalId : nil
        }
        let idsToFetch = Array(uncachedIDs.prefix(Self.maxTitleEnrichmentsPerPass))
        guard !idsToFetch.isEmpty else { return }

        titleEnrichmentTask = Task { [weak self] in
            guard let self else { return }
            for id in idsToFetch {
                if Task.isCancelled { return }
                do {
                    let response = try await self.animeDetailService.fetchAnimeDetail(malId: id)
                    let anime = response.data
                    let title = Self.preferredTitle(
                        japanese: anime.titleJapanese,
                        english: anime.titleEnglish,
                        fallback: anime.title
                    )
                    Self.storeTitle(title, for: id)
                    self.replaceRecommendedTitle(for: id, with: title)
                    try? await Task.sleep(nanoseconds: Self.titleEnrichmentDelayNanoseconds)
                } catch {
                    continue
                }
            }

            if !Task.isCancelled {
                startTitleEnrichmentIfNeeded()
            }
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

    private static func cachedTitle(for malId: Int) -> String? {
        titleCache[malId]
    }

    private static func storeTitle(_ title: String, for malId: Int) {
        titleCache[malId] = title
        titleCacheOrder.removeAll { $0 == malId }
        titleCacheOrder.append(malId)
        while titleCacheOrder.count > titleCacheLimit {
            let removed = titleCacheOrder.removeFirst()
            titleCache.removeValue(forKey: removed)
        }
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

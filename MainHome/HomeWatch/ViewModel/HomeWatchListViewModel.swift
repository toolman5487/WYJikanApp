//
//  HomeWatchListViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Combine
import Foundation

@MainActor
final class HomeWatchListViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content([HomeWatchListItem])
        case empty
        case error(message: String)
    }

    typealias LoadMoreState = PaginationFooterState

    @Published private(set) var selectedFeed: HomeWatchFeedKind
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let service: HomeWatchServicing
    private let pageSize = 12
    private var pagination = PaginatedListState<HomeWatchListItem>()
    private var feedChangeTask: Task<Void, Never>?

    init(
        initialFeed: HomeWatchFeedKind = .latestEpisodes,
        service: HomeWatchServicing = HomeWatchService()
    ) {
        self.selectedFeed = initialFeed
        self.service = service
    }

    deinit {
        feedChangeTask?.cancel()
    }

    var headerContent: HomeWatchListHeaderContent {
        HomeWatchListHeaderContent(
            title: selectedFeed.title,
            subtitle: selectedFeed.subtitle,
            loadedCountText: "已載入 \(pagination.items.count) 筆"
        )
    }

    var feedChipItems: [HomeWatchFeedChipItem] {
        HomeWatchFeedKind.allCases.map { feed in
            HomeWatchFeedChipItem(
                feed: feed,
                isSelected: selectedFeed == feed
            )
        }
    }

    func loadIfNeeded() async {
        guard !pagination.hasLoaded else { return }
        await fetchFirstPage(showSkeleton: true, forceRefresh: false)
    }

    func reload() async {
        await fetchFirstPage(showSkeleton: true, forceRefresh: true)
    }

    func loadMore() async {
        await loadMorePage()
    }

    func retryLoadMore() async {
        guard case .error = loadMoreState else { return }
        await loadMorePage()
    }

    func selectFeed(_ feed: HomeWatchFeedKind) {
        guard selectedFeed != feed else { return }
        selectedFeed = feed
        feedChangeTask?.cancel()
        feedChangeTask = Task { [weak self] in
            guard let self else { return }
            await self.fetchFirstPage(showSkeleton: true, forceRefresh: false)
        }
    }

    private func fetchFirstPage(showSkeleton: Bool, forceRefresh: Bool) async {
        let feed = selectedFeed
        let generation = pagination.beginReload(clearItems: showSkeleton)

        if showSkeleton {
            screenState = .loading
            loadMoreState = pagination.footerState
        }

        do {
            let page = try await fetchPage(feed: feed, page: 1, forceRefresh: forceRefresh)
            guard selectedFeed == feed,
                  pagination.finishReload(page, generation: generation) else { return }
            applyPresentation()
        } catch is CancellationError {
            return
        } catch {
            guard selectedFeed == feed,
                  pagination.isCurrent(generation) else { return }
            screenState = .error(message: error.userFacingMessage)
            loadMoreState = .hidden
        }
    }

    private func loadMorePage() async {
        let feed = selectedFeed
        guard let generation = pagination.beginLoadMore() else { return }
        loadMoreState = pagination.footerState

        do {
            let page = try await fetchPage(feed: feed, page: pagination.currentPage + 1, forceRefresh: false)
            guard selectedFeed == feed,
                  pagination.finishLoadMore(
                page,
                generation: generation,
                requiresNewItemsForNextPage: true
            ) else { return }
            applyPresentation()
        } catch is CancellationError {
            if pagination.cancelLoadMore(generation: generation) {
                loadMoreState = pagination.footerState
            }
            return
        } catch {
            guard pagination.failLoadMore(message: "載入更多失敗", generation: generation) else { return }
            loadMoreState = pagination.footerState
        }
    }

    private func fetchPage(
        feed: HomeWatchFeedKind,
        page: Int,
        forceRefresh: Bool
    ) async throws -> PaginatedPage<HomeWatchListItem> {
        if let episodeFeed = feed.episodeFeed {
            let response = try await service.fetchEpisodes(
                feed: episodeFeed,
                page: page,
                limit: pageSize,
                forceRefresh: forceRefresh
            )
            let items = response.data.compactMap { Self.item(from: $0, feed: feed) }
            return PaginatedPage(
                items: items,
                currentPage: response.pagination?.currentPage ?? page,
                hasNextPage: response.pagination?.hasNextPage ?? !items.isEmpty
            )
        }

        guard let promoFeed = feed.promoFeed else {
            return PaginatedPage(items: [], currentPage: page, hasNextPage: false)
        }

        let response = try await service.fetchPromos(
            feed: promoFeed,
            page: page,
            limit: pageSize,
            forceRefresh: forceRefresh
        )
        let items = response.data.compactMap { Self.item(from: $0, feed: feed) }
        return PaginatedPage(
            items: items,
            currentPage: response.pagination?.currentPage ?? page,
            hasNextPage: response.pagination?.hasNextPage ?? !items.isEmpty
        )
    }

    private func applyPresentation() {
        guard !pagination.items.isEmpty else {
            screenState = .empty
            loadMoreState = .hidden
            return
        }

        screenState = .content(pagination.items)
        loadMoreState = pagination.footerState
    }

    private static func item(from dto: HomeWatchEpisodeGroupDTO, feed: HomeWatchFeedKind) -> HomeWatchListItem? {
        guard let entry = dto.entry else { return nil }
        let firstEpisode = dto.episodes.first
        let actionURL = url(from: firstEpisode?.url)
        let episodeText = episodeText(from: firstEpisode)

        return HomeWatchListItem(
            id: "\(feed.id)-episode-\(entry.malId)",
            animeID: entry.malId,
            title: HomeWatchPresentationText.title(from: entry),
            subtitle: episodeText,
            imageURL: posterURL(from: entry.images),
            badgeTexts: badgeTexts(from: dto),
            actionURL: actionURL,
            contentKind: .episode
        )
    }

    private static func item(from dto: HomeWatchPromoDTO, feed: HomeWatchFeedKind) -> HomeWatchListItem? {
        guard let entry = dto.entry else { return nil }
        let promoTitle = normalizedText(dto.title) ?? "最新預告"
        let watchURL = watchURL(from: dto.trailer)
        let thumbnailURL = thumbnailURL(from: dto.trailer) ?? posterURL(from: entry.images)
        let id = [
            feed.id,
            "promo",
            String(entry.malId),
            promoTitle,
            watchURL?.absoluteString ?? thumbnailURL?.absoluteString ?? "item"
        ].joined(separator: "-")

        return HomeWatchListItem(
            id: id,
            animeID: entry.malId,
            title: HomeWatchPresentationText.title(from: entry),
            subtitle: promoTitle,
            imageURL: thumbnailURL,
            badgeTexts: ["預告"],
            actionURL: watchURL,
            contentKind: .promo
        )
    }

    private static func episodeText(from episode: HomeWatchEpisodeDTO?) -> String {
        guard let episode else { return "最新集數" }

        return HomeWatchPresentationText.episodeText(
            title: episode.title,
            episodeID: episode.malId,
            fallback: "最新集數"
        )
    }

    private static func badgeTexts(from dto: HomeWatchEpisodeGroupDTO) -> [String] {
        var badges: [String] = ["集數"]

        if dto.regionLocked == true {
            badges.append("地區限制")
        }

        if dto.episodes.contains(where: { $0.premium == true }) {
            badges.append("付費")
        }

        return badges
    }

    private static func watchURL(from trailer: HomeWatchTrailerDTO?) -> URL? {
        if let url = url(from: trailer?.url) {
            return url
        }

        if let youtubeID = normalizedText(trailer?.youtubeId) {
            return URL(string: "https://www.youtube.com/watch?v=\(youtubeID)")
        }

        return url(from: trailer?.embedUrl)
    }

    private static func thumbnailURL(from trailer: HomeWatchTrailerDTO?) -> URL? {
        [
            trailer?.images?.maximumImageUrl,
            trailer?.images?.largeImageUrl,
            trailer?.images?.mediumImageUrl,
            trailer?.images?.imageUrl,
            trailer?.images?.smallImageUrl
        ]
        .compactMap(url(from:))
        .first
    }

    private static func posterURL(from images: AnimeImagesDTO?) -> URL? {
        [
            images?.webp?.largeImageUrl,
            images?.jpg?.largeImageUrl,
            images?.webp?.imageUrl,
            images?.jpg?.imageUrl
        ]
        .compactMap(url(from:))
        .first
    }

    private static func url(from value: String?) -> URL? {
        guard let text = normalizedText(value) else { return nil }
        return URL(string: text)
    }

    private static func normalizedText(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }
        return text
    }
}

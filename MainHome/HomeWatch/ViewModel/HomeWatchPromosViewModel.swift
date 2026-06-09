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

    init(service: HomeWatchServicing = HomeWatchService()) {
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
            let mapped = response.data.compactMap(Self.item(from:))
            var seenIDs = Set<String>()
            let items = mapped
                .filter { seenIDs.insert($0.id).inserted }
                .prefix(Self.maxCards)

            screenState = items.isEmpty ? .empty : .content(Array(items))
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

    private static func item(from dto: HomeWatchPromoDTO) -> HomeWatchPromoItem? {
        guard let entry = dto.entry else { return nil }
        let promoTitle = normalizedText(dto.title) ?? "最新預告"
        let watchURL = watchURL(from: dto.trailer)
        let thumbnailURL = thumbnailURL(from: dto.trailer) ?? posterURL(from: entry.images)
        let id = [
            String(entry.malId),
            promoTitle,
            watchURL?.absoluteString ?? thumbnailURL?.absoluteString ?? "promo"
        ].joined(separator: "-")

        return HomeWatchPromoItem(
            id: id,
            animeID: entry.malId,
            animeTitle: HomeWatchPresentationText.title(from: entry),
            promoTitle: promoTitle,
            thumbnailURL: thumbnailURL,
            watchURL: watchURL
        )
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

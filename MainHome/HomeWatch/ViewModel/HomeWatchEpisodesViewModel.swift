//
//  HomeWatchEpisodesViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Combine
import Foundation

@MainActor
final class HomeWatchEpisodesViewModel: ObservableObject {
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

    @Published private(set) var screenState: HomeWatchSectionState<HomeWatchEpisodeItem> = .loading

    private let service: HomeWatchServicing
    private var loadState: LoadState = .idle

    init(service: HomeWatchServicing = HomeWatchService()) {
        self.service = service
    }

    deinit {
        loadState.task?.cancel()
    }

    var items: [HomeWatchEpisodeItem] {
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
            let response = try await service.fetchLatestEpisodes(forceRefresh: forceRefresh)
            let mapped = response.data.compactMap(Self.item(from:))
            var seenIDs = Set<Int>()
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

    private static func item(from dto: HomeWatchEpisodeGroupDTO) -> HomeWatchEpisodeItem? {
        guard let entry = dto.entry,
              let imageURL = posterURL(from: entry.images) else {
            return nil
        }

        return HomeWatchEpisodeItem(
            id: entry.malId,
            title: HomeWatchPresentationText.title(from: entry),
            imageURL: imageURL,
            episodeText: episodeText(from: dto.episodes),
            episodeURL: url(from: dto.episodes.first?.url),
            badgeTexts: badgeTexts(from: dto)
        )
    }

    private static func episodeText(from episodes: [HomeWatchEpisodeDTO]) -> String {
        guard let firstEpisode = episodes.first else {
            return "最新集數"
        }

        return HomeWatchPresentationText.episodeText(
            title: firstEpisode.title,
            episodeID: firstEpisode.malId,
            fallback: "最新集數"
        )
    }

    private static func badgeTexts(from dto: HomeWatchEpisodeGroupDTO) -> [String] {
        var badges: [String] = []

        if dto.regionLocked == true {
            badges.append("地區限制")
        }

        if dto.episodes.contains(where: { $0.premium == true }) {
            badges.append("付費")
        }

        return badges
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

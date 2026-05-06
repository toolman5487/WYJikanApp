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

    func load() {
        loadTask?.cancel()
        titleEnrichmentTask?.cancel()
        isLoading = true
        screenState = .loading
        visibleCount = Self.initialVisibleCards

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchRecommendedAnime(limit: Self.maxCards)
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
                self.isLoading = false
                self.screenState = items.isEmpty ? .empty : .content(items)
                self.startTitleEnrichmentIfNeeded()
            } catch {
                self.isLoading = false
                self.screenState = .error(error.localizedDescription)
            }
        }
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil
        titleEnrichmentTask?.cancel()
        titleEnrichmentTask = nil
    }

    func loadMore() {
        visibleCount = min(visibleCount + Self.loadMoreStep, allItems.count)
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
                    let response = try await self.service.fetchAnimeDetail(malId: id)
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

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
    case error(FeatureLoadFailure)
    case empty
    case content([HomeTodayAnimeCardItem])

    var items: [HomeTodayAnimeCardItem] {
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
final class HomeTodayAnimeViewModel: ObservableObject {
    private static let maxCards = 10
    private static let scheduleFetchLimit = 25

    @Published private(set) var screenState: HomeTodayAnimeScreenState = .loading

    private let service: MainHomeServicing
    private let sectionLoader = HomeFeedSectionLoader()

    init(service: MainHomeServicing) {
        self.service = service
    }

    deinit {
        sectionLoader.cancel()
    }

    var items: [HomeTodayAnimeCardItem] {
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
            let response = try await service.fetchTodayAnime(
                limit: Self.scheduleFetchLimit,
                forceRefresh: forceRefresh
            )
            let mapped: [HomeTodayAnimeCardItem] = response.data.compactMap { dto -> HomeTodayAnimeCardItem? in
                guard let url = JikanImageURLResolver.url(from: dto.images, tier: .card)
                else { return nil }

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
            if forceRefresh, previousState.hasContent {
                screenState = previousState
            } else {
                screenState = .error(FeatureLoadFailure(error))
            }
        }
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

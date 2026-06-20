//
//  TrendingMangaViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Combine
import Foundation

typealias HomeTrendingMangaScreenState = LoadableContentState<[HomeTrendingMangaCardItem]>

// MARK: - HomeTrendingMangaViewModel

@MainActor
final class HomeTrendingMangaViewModel: ObservableObject {

    // MARK: - Properties

    private static let maxCards = 10

    @Published private(set) var screenState: HomeTrendingMangaScreenState = .loading

    private let service: MainHomeServicing
    private let sectionLoader = HomeFeedSectionLoader()

    // MARK: - Lifecycle

    init(service: MainHomeServicing) {
        self.service = service
    }

    isolated deinit {
        sectionLoader.cancel()
    }

    // MARK: - Derived State

    var items: [HomeTrendingMangaCardItem] {
        screenState.items
    }

    // MARK: - Public Methods

    func loadIfNeeded(priority: TaskPriority = .userInitiated) {
        sectionLoader.loadIfNeeded(isContentEmpty: items.isEmpty) {
            load(priority: priority)
        }
    }

    func refresh() async {
        await sectionLoader.refresh(hasContent: screenState.hasContent) { [weak self] forceRefresh, showsLoadingState in
            await self?.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
    }

    func load(priority: TaskPriority = .userInitiated) {
        sectionLoader.load(priority: priority) { [weak self] forceRefresh, showsLoadingState in
            await self?.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
    }

    // MARK: - Private Methods

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        defer {
            sectionLoader.markIdle()
        }

        if showsLoadingState {
            screenState = .loading
        }

        do {
            let response = try await service.fetchTopManga(
                limit: Self.maxCards,
                forceRefresh: forceRefresh
            )

            let mapped: [HomeTrendingMangaCardItem] = response.data.compactMap { dto -> HomeTrendingMangaCardItem? in
                guard let urlString = dto.imgUrl,
                      let url = URL(string: urlString) else { return nil }

                return HomeTrendingMangaCardItem(
                    id: dto.id,
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

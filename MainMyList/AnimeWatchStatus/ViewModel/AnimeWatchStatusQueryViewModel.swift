//
//  AnimeWatchStatusQueryViewModel.swift
//  WYJikanApp
//

import Combine
import Foundation
import OSLog

@MainActor
final class AnimeWatchStatusQueryViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var presentation = AnimeWatchStatusPresentation(
        summary: .empty,
        filteredItems: []
    )
    @Published var selectedFilter: AnimeWatchStatusFilter = .all {
        didSet {
            guard selectedFilter != oldValue else { return }
            rebuildPresentation()
        }
    }

    // MARK: - Dependencies

    private let favoriteRepository: any FavoriteRepository
    private var cachedAnimeItems: [MyListCollectionItem] = []
    private var myListCancellable: AnyCancellable?

    // MARK: - Lifecycle

    init(favoriteRepository: any FavoriteRepository) {
        self.favoriteRepository = favoriteRepository
        connectToRepository()
    }

    // MARK: - Repository

    private func connectToRepository() {
        guard myListCancellable == nil else { return }

        myListCancellable = favoriteRepository.myListPublisher
            .sink { [weak self] items in
                self?.apply(items: items)
            }

        do {
            try favoriteRepository.reloadFavorites()
        } catch {
            AppLogger.persistence.error(
                "Anime watch status reload failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func apply(items: [MyListCollectionItem]) {
        cachedAnimeItems = items
            .filter { $0.mediaKind == .anime }
            .sorted(by: compareAnimeItems)
        rebuildPresentation()
    }

    // MARK: - Presentation

    private func rebuildPresentation() {
        presentation = AnimeWatchStatusPresentation(
            summary: makeSummary(from: cachedAnimeItems),
            filteredItems: filteredItems(from: cachedAnimeItems)
        )
    }

    private func makeSummary(from items: [MyListCollectionItem]) -> AnimeWatchStatusSummary {
        var countsByStatus: [AnimeWatchStatus: Int] = [:]

        for item in items {
            countsByStatus[item.animeWatchStatus, default: 0] += 1
        }

        let statusCounts = AnimeWatchStatusFilter.allCases.map { filter in
            AnimeWatchStatusCount(
                filter: filter,
                count: count(for: filter, in: items, countsByStatus: countsByStatus)
            )
        }

        return AnimeWatchStatusSummary(
            totalCount: items.count,
            watchingCount: countsByStatus[.watching, default: 0],
            plannedCount: countsByStatus[.planned, default: 0],
            completedCount: countsByStatus[.completed, default: 0],
            statusCounts: statusCounts
        )
    }

    private func filteredItems(from items: [MyListCollectionItem]) -> [MyListCollectionItem] {
        switch selectedFilter {
        case .all:
            return items
        case .status(let status):
            return items.filter { $0.animeWatchStatus == status }
        }
    }

    private func count(
        for filter: AnimeWatchStatusFilter,
        in items: [MyListCollectionItem],
        countsByStatus: [AnimeWatchStatus: Int]
    ) -> Int {
        switch filter {
        case .all:
            return items.count
        case .status(let status):
            return countsByStatus[status, default: 0]
        }
    }

    // MARK: - Sorting

    private func compareAnimeItems(_ lhs: MyListCollectionItem, _ rhs: MyListCollectionItem) -> Bool {
        switch (lhs.progressUpdatedAt, rhs.progressUpdatedAt) {
        case let (left?, right?):
            if left == right {
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
            return left > right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            if lhs.addedAt == rhs.addedAt {
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
            return lhs.addedAt > rhs.addedAt
        }
    }
}

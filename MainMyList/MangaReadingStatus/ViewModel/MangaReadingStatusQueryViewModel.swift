//
//  MangaReadingStatusQueryViewModel.swift
//  WYJikanApp
//

import Combine
import Foundation
import OSLog

@MainActor
final class MangaReadingStatusQueryViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var presentation = MangaReadingStatusPresentation(
        summary: .empty,
        filteredItems: []
    )
    @Published var selectedFilter: MangaReadingStatusFilter = .all {
        didSet {
            guard selectedFilter != oldValue else { return }
            rebuildPresentation()
        }
    }

    // MARK: - Dependencies

    private let favoriteRepository: any FavoriteRepository
    private var cachedMangaItems: [MyListCollectionItem] = []
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
                "Manga reading status reload failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func apply(items: [MyListCollectionItem]) {
        cachedMangaItems = items
            .filter { $0.mediaKind == .manga }
            .sorted(by: compareMangaItems)
        rebuildPresentation()
    }

    // MARK: - Presentation

    private func rebuildPresentation() {
        presentation = MangaReadingStatusPresentation(
            summary: makeSummary(from: cachedMangaItems),
            filteredItems: filteredItems(from: cachedMangaItems)
        )
    }

    private func makeSummary(from items: [MyListCollectionItem]) -> MangaReadingStatusSummary {
        var countsByStatus: [MangaReadingStatus: Int] = [:]

        for item in items {
            countsByStatus[item.mangaReadingStatus, default: 0] += 1
        }

        let statusCounts = MangaReadingStatusFilter.allCases.map { filter in
            MangaReadingStatusCount(
                filter: filter,
                count: count(for: filter, in: items, countsByStatus: countsByStatus)
            )
        }

        return MangaReadingStatusSummary(
            totalCount: items.count,
            readingCount: countsByStatus[.reading, default: 0],
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
            return items.filter { $0.mangaReadingStatus == status }
        }
    }

    private func count(
        for filter: MangaReadingStatusFilter,
        in items: [MyListCollectionItem],
        countsByStatus: [MangaReadingStatus: Int]
    ) -> Int {
        switch filter {
        case .all:
            return items.count
        case .status(let status):
            return countsByStatus[status, default: 0]
        }
    }

    // MARK: - Sorting

    private func compareMangaItems(_ lhs: MyListCollectionItem, _ rhs: MyListCollectionItem) -> Bool {
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

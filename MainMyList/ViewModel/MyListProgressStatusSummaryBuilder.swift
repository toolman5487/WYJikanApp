//
//  MyListProgressStatusSummaryBuilder.swift
//  WYJikanApp
//

import Foundation

nonisolated struct MyListProgressStatusSummaryBuilder: Sendable {

    // MARK: - Anime

    func makeAnimeWatchStatusSummary(
        from items: [MyListItemSnapshot]
    ) -> AnimeWatchStatusSummary {
        let animeItems = items.filter { $0.mediaKind == .anime }
        var countsByStatus: [AnimeWatchStatus: Int] = [:]

        for item in animeItems {
            countsByStatus[item.animeWatchStatus, default: 0] += 1
        }

        let statusCounts = AnimeWatchStatusFilter.allCases.map { filter in
            AnimeWatchStatusCount(
                filter: filter,
                count: animeWatchStatusCount(
                    for: filter,
                    in: animeItems,
                    countsByStatus: countsByStatus
                )
            )
        }

        return AnimeWatchStatusSummary(
            totalCount: animeItems.count,
            watchingCount: countsByStatus[.watching, default: 0],
            plannedCount: countsByStatus[.planned, default: 0],
            completedCount: countsByStatus[.completed, default: 0],
            statusCounts: statusCounts
        )
    }

    private func animeWatchStatusCount(
        for filter: AnimeWatchStatusFilter,
        in animeItems: [MyListItemSnapshot],
        countsByStatus: [AnimeWatchStatus: Int]
    ) -> Int {
        switch filter {
        case .all:
            return animeItems.count
        case .status(let status):
            return countsByStatus[status, default: 0]
        }
    }

    // MARK: - Manga

    func makeMangaReadingStatusSummary(
        from items: [MyListItemSnapshot]
    ) -> MangaReadingStatusSummary {
        let mangaItems = items.filter { $0.mediaKind == .manga }
        var countsByStatus: [MangaReadingStatus: Int] = [:]

        for item in mangaItems {
            countsByStatus[item.mangaReadingStatus, default: 0] += 1
        }

        let statusCounts = MangaReadingStatusFilter.allCases.map { filter in
            MangaReadingStatusCount(
                filter: filter,
                count: mangaReadingStatusCount(
                    for: filter,
                    in: mangaItems,
                    countsByStatus: countsByStatus
                )
            )
        }

        return MangaReadingStatusSummary(
            totalCount: mangaItems.count,
            readingCount: countsByStatus[.reading, default: 0],
            plannedCount: countsByStatus[.planned, default: 0],
            completedCount: countsByStatus[.completed, default: 0],
            statusCounts: statusCounts
        )
    }

    private func mangaReadingStatusCount(
        for filter: MangaReadingStatusFilter,
        in mangaItems: [MyListItemSnapshot],
        countsByStatus: [MangaReadingStatus: Int]
    ) -> Int {
        switch filter {
        case .all:
            return mangaItems.count
        case .status(let status):
            return countsByStatus[status, default: 0]
        }
    }
}

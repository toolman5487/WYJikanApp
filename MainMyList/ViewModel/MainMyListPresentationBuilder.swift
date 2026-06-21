//
//  MainMyListPresentationBuilder.swift
//  WYJikanApp
//

import Foundation

nonisolated struct MainMyListPresentationBuilder: Sendable {

    // MARK: - Dependencies

    private let statisticsBuilder: MyListStatisticsBuilder
    private let progressStatusSummaryBuilder: MyListProgressStatusSummaryBuilder

    // MARK: - Lifecycle

    init(
        statisticsBuilder: MyListStatisticsBuilder = MyListStatisticsBuilder(),
        progressStatusSummaryBuilder: MyListProgressStatusSummaryBuilder = MyListProgressStatusSummaryBuilder()
    ) {
        self.statisticsBuilder = statisticsBuilder
        self.progressStatusSummaryBuilder = progressStatusSummaryBuilder
    }

    // MARK: - Build

    func makePresentation(
        from items: [MyListItemSnapshot],
        selectedFilter: MyListFilter
    ) -> MyListPresentation {
        let statisticsResult = statisticsBuilder.build(
            from: items,
            selectedFilter: selectedFilter
        )

        return MyListPresentation(
            filteredItems: statisticsResult.filteredItems,
            genreSections: MyListGenreCollectionsSectionBuilder.makeSections(
                from: statisticsResult.filteredItems
            ),
            formatSections: MyListFormatCollectionsSectionBuilder.makeSections(
                from: statisticsResult.filteredItems
            ),
            statistics: statisticsResult.statistics,
            summaryTile: summaryTile(
                selectedFilter: selectedFilter,
                statisticsResult: statisticsResult,
                totalCount: items.count
            ),
            animeWatchStatusSummary: progressStatusSummaryBuilder.makeAnimeWatchStatusSummary(
                from: items
            ),
            mangaReadingStatusSummary: progressStatusSummaryBuilder.makeMangaReadingStatusSummary(
                from: items
            )
        )
    }

    func emptyPresentation(selectedFilter: MyListFilter) -> MyListPresentation {
        MyListPresentation(
            filteredItems: [],
            genreSections: [],
            formatSections: [],
            statistics: statisticsBuilder.emptyStatistics(selectedFilter: selectedFilter),
            summaryTile: emptySummaryTile(selectedFilter: selectedFilter),
            animeWatchStatusSummary: .empty,
            mangaReadingStatusSummary: .empty
        )
    }

    // MARK: - Summary Tile

    private func summaryTile(
        selectedFilter: MyListFilter,
        statisticsResult: MyListStatisticsBuildResult,
        totalCount: Int
    ) -> MyListSummaryContent {
        switch selectedFilter {
        case .all:
            return .init(
                title: "全部收藏",
                value: totalCount,
                iconName: "heart.fill",
                detail: weeklyAddedSummary(
                    count: statisticsResult.weeklyAddedCount,
                    filterTitle: nil
                )
            )
        case .anime:
            return .init(
                title: "動畫收藏",
                value: statisticsResult.animeCount,
                iconName: MyListMediaKind.anime.iconName,
                detail: weeklyAddedSummary(
                    count: statisticsResult.weeklyAnimeAddedCount,
                    filterTitle: MyListFilter.anime.title
                )
            )
        case .manga:
            return .init(
                title: "漫畫收藏",
                value: statisticsResult.mangaCount,
                iconName: MyListMediaKind.manga.iconName,
                detail: weeklyAddedSummary(
                    count: statisticsResult.weeklyMangaAddedCount,
                    filterTitle: MyListFilter.manga.title
                )
            )
        }
    }

    private func emptySummaryTile(selectedFilter: MyListFilter) -> MyListSummaryContent {
        switch selectedFilter {
        case .all:
            return .init(
                title: "全部收藏",
                value: 0,
                iconName: "heart.fill",
                detail: "最近 7 天新增 0 筆收藏"
            )
        case .anime:
            return .init(
                title: "動畫收藏",
                value: 0,
                iconName: MyListMediaKind.anime.iconName,
                detail: "最近 7 天新增 0 筆動畫收藏"
            )
        case .manga:
            return .init(
                title: "漫畫收藏",
                value: 0,
                iconName: MyListMediaKind.manga.iconName,
                detail: "最近 7 天新增 0 筆漫畫收藏"
            )
        }
    }

    private func weeklyAddedSummary(count: Int, filterTitle: String?) -> String {
        switch filterTitle {
        case .some(let title):
            return "最近 7 天新增 \(count) 筆\(title)收藏"
        case .none:
            return "最近 7 天新增 \(count) 筆收藏"
        }
    }
}

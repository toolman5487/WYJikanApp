//
//  MainMyListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Combine
import Foundation
import OSLog

@MainActor
final class MainMyListViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var presentation: MyListPresentation
    @Published var selectedFilter: MyListFilter = .all {
        didSet {
            guard selectedFilter != oldValue else { return }
            rebuildPresentationFromCachedItems()
        }
    }

    // MARK: - Dependencies

    private let favoriteRepository: any FavoriteRepository
    private var cachedItems: [MyListCollectionItem] = []
    private var myListCancellable: AnyCancellable?

    // MARK: - Lifecycle

    init(favoriteRepository: any FavoriteRepository) {
        self.favoriteRepository = favoriteRepository
        self.presentation = Self.emptyPresentation(selectedFilter: .all)
        connectToRepository()
    }

    // MARK: - Public Methods

    func remove(_ item: MyListCollectionItem) {
        do {
            try favoriteRepository.remove(item)
        } catch {
            AppLogger.persistence.error("MyList delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func emptyTitle(for filter: MyListFilter) -> String {
        filter == .all ? "還沒有收藏" : "還沒有收藏\(filter.title)"
    }

    func emptyState() -> MyListEmptyState {
        let title = emptyTitle(for: selectedFilter)
        let message = "在作品詳情頁點右上角的愛心，就會加入收藏。"

        guard let selectedMediaKind = selectedFilter.mediaKind else {
            return .emptyCollection(title: title, message: message)
        }

        let hasOtherMedia = cachedItems.contains { $0.mediaKind != selectedMediaKind }
        if hasOtherMedia {
            return .filteredEmpty(title: title, message: message)
        }
        return .emptyCollection(title: title, message: message)
    }

    // MARK: - Repository

    private func connectToRepository() {
        guard myListCancellable == nil else { return }

        myListCancellable = favoriteRepository.myListPublisher
            .sink { [weak self] items in
                self?.applyItems(items)
            }

        do {
            try favoriteRepository.reloadFavorites()
        } catch {
            AppLogger.persistence.error(
                "MyList reload failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func applyItems(_ items: [MyListCollectionItem]) {
        cachedItems = items
        rebuildPresentationFromCachedItems()
    }

    // MARK: - Presentation

    private func rebuildPresentationFromCachedItems() {
        presentation = makePresentation(
            from: cachedItems,
            selectedFilter: selectedFilter
        )
    }

    private func makePresentation(
        from items: [MyListCollectionItem],
        selectedFilter: MyListFilter
    ) -> MyListPresentation {
        let calendar = Calendar.current
        let now = Date()
        let weekStartDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))
            ?? calendar.startOfDay(for: now)

        let selectedMediaKind = selectedFilter.mediaKind
        var animeCount = 0
        var mangaCount = 0
        var weeklyAddedCount = 0
        var weeklyAnimeAddedCount = 0
        var weeklyMangaAddedCount = 0
        var filteredItems: [MyListCollectionItem] = []
        filteredItems.reserveCapacity(items.count)

        for item in items {
            switch item.mediaKind {
            case .anime:
                animeCount += 1
            case .manga:
                mangaCount += 1
            }

            if item.addedAt >= weekStartDate {
                weeklyAddedCount += 1

                switch item.mediaKind {
                case .anime:
                    weeklyAnimeAddedCount += 1
                case .manga:
                    weeklyMangaAddedCount += 1
                }
            }

            if selectedMediaKind == nil || selectedMediaKind == item.mediaKind {
                filteredItems.append(item)
            }
        }

        let allAnalysis = makeGenreAnalysis(
            from: items,
            scope: .all
        )
        let animeAnalysis = makeGenreAnalysis(
            from: items.filter { $0.mediaKind == .anime },
            scope: .anime
        )
        let mangaAnalysis = makeGenreAnalysis(
            from: items.filter { $0.mediaKind == .manga },
            scope: .manga
        )
        let selectedAnalysis: MyListGenreAnalysis
        switch selectedFilter {
        case .all:
            selectedAnalysis = allAnalysis
        case .anime:
            selectedAnalysis = animeAnalysis
        case .manga:
            selectedAnalysis = mangaAnalysis
        }
        let formatAnalysis = makeFormatAnalysis(
            from: filteredItems,
            scope: selectedAnalysis.scope
        )

        let statistics = MyListStatistics(
            totalCount: items.count,
            animeCount: animeCount,
            mangaCount: mangaCount,
            allAnalysis: allAnalysis,
            animeAnalysis: animeAnalysis,
            mangaAnalysis: mangaAnalysis,
            selectedAnalysis: selectedAnalysis,
            formatAnalysis: formatAnalysis
        )

        let summaryTile: MyListSummaryContent
        switch selectedFilter {
        case .all:
            summaryTile = .init(
                title: "全部收藏",
                value: items.count,
                iconName: "heart.fill",
                detail: weeklyAddedSummary(
                    count: weeklyAddedCount,
                    filterTitle: nil
                )
            )
        case .anime:
            summaryTile = .init(
                title: "動畫收藏",
                value: animeCount,
                iconName: MyListMediaKind.anime.iconName,
                detail: weeklyAddedSummary(
                    count: weeklyAnimeAddedCount,
                    filterTitle: MyListFilter.anime.title
                )
            )
        case .manga:
            summaryTile = .init(
                title: "漫畫收藏",
                value: mangaCount,
                iconName: MyListMediaKind.manga.iconName,
                detail: weeklyAddedSummary(
                    count: weeklyMangaAddedCount,
                    filterTitle: MyListFilter.manga.title
                )
            )
        }

        return MyListPresentation(
            filteredItems: filteredItems,
            genreSections: MyListGenreCollectionsSectionBuilder.makeSections(from: filteredItems),
            formatSections: MyListFormatCollectionsSectionBuilder.makeSections(from: filteredItems),
            statistics: statistics,
            summaryTile: summaryTile,
            mangaReadingStatusSummary: makeMangaReadingStatusSummary(from: items)
        )
    }

    private static func emptyPresentation(selectedFilter: MyListFilter) -> MyListPresentation {
        let emptyAllAnalysis = MyListGenreAnalysis(
            scope: .all,
            itemCount: 0,
            genreSlices: [],
            missingGenreItemCount: 0
        )
        let emptyAnimeAnalysis = MyListGenreAnalysis(
            scope: .anime,
            itemCount: 0,
            genreSlices: [],
            missingGenreItemCount: 0
        )
        let emptyMangaAnalysis = MyListGenreAnalysis(
            scope: .manga,
            itemCount: 0,
            genreSlices: [],
            missingGenreItemCount: 0
        )

        let selectedAnalysis: MyListGenreAnalysis
        let summaryTile: MyListSummaryContent
        switch selectedFilter {
        case .all:
            selectedAnalysis = emptyAllAnalysis
            summaryTile = .init(
                title: "全部收藏",
                value: 0,
                iconName: "heart.fill",
                detail: "最近 7 天新增 0 筆收藏"
            )
        case .anime:
            selectedAnalysis = emptyAnimeAnalysis
            summaryTile = .init(
                title: "動畫收藏",
                value: 0,
                iconName: MyListMediaKind.anime.iconName,
                detail: "最近 7 天新增 0 筆動畫收藏"
            )
        case .manga:
            selectedAnalysis = emptyMangaAnalysis
            summaryTile = .init(
                title: "漫畫收藏",
                value: 0,
                iconName: MyListMediaKind.manga.iconName,
                detail: "最近 7 天新增 0 筆漫畫收藏"
            )
        }

        let statistics = MyListStatistics(
            totalCount: 0,
            animeCount: 0,
            mangaCount: 0,
            allAnalysis: emptyAllAnalysis,
            animeAnalysis: emptyAnimeAnalysis,
            mangaAnalysis: emptyMangaAnalysis,
            selectedAnalysis: selectedAnalysis,
            formatAnalysis: MyListFormatAnalysis(
                scope: selectedAnalysis.scope,
                itemCount: 0,
                formatSlices: [],
                missingTypeItemCount: 0
            )
        )

        return MyListPresentation(
            filteredItems: [],
            genreSections: [],
            formatSections: [],
            statistics: statistics,
            summaryTile: summaryTile,
            mangaReadingStatusSummary: .empty
        )
    }

    // MARK: - Analysis

    private func makeGenreAnalysis(
        from items: [MyListCollectionItem],
        scope: MyListStatisticsScope
    ) -> MyListGenreAnalysis {
        var genreCounts: [String: Int] = [:]
        var missingGenreItemCount = 0

        for item in items {
            let genreNames = item.genreNames
            if genreNames.isEmpty {
                missingGenreItemCount += 1
            } else {
                for genreName in genreNames {
                    genreCounts[genreName, default: 0] += 1
                }
            }
        }

        let genreSlices = genreCounts
            .map { genreName, count in
                MyListGenreSlice(genreName: genreName, count: count)
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.genreName.localizedStandardCompare(rhs.genreName) == .orderedAscending
                }
                return lhs.count > rhs.count
            }

        return MyListGenreAnalysis(
            scope: scope,
            itemCount: items.count,
            genreSlices: Array(genreSlices.prefix(6)),
            missingGenreItemCount: missingGenreItemCount
        )
    }

    private func makeFormatAnalysis(
        from items: [MyListCollectionItem],
        scope: MyListStatisticsScope
    ) -> MyListFormatAnalysis {
        var formatCounts: [String: Int] = [:]
        var missingTypeItemCount = 0

        for item in items {
            guard let format = MyListFormatDisplay.displayItem(
                type: item.type,
                mediaKind: item.mediaKind
            ) else {
                missingTypeItemCount += 1
                continue
            }

            formatCounts[format.title, default: 0] += 1
        }

        let formatSlices = formatCounts
            .map { title, count in
                MyListFormatSlice(
                    title: title,
                    iconName: MyListFormatDisplay.iconName(forFormatTitle: title),
                    count: count
                )
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }
                return lhs.count > rhs.count
            }

        return MyListFormatAnalysis(
            scope: scope,
            itemCount: items.count,
            formatSlices: Array(formatSlices.prefix(6)),
            missingTypeItemCount: missingTypeItemCount
        )
    }

    private func makeMangaReadingStatusSummary(
        from items: [MyListCollectionItem]
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
        in mangaItems: [MyListCollectionItem],
        countsByStatus: [MangaReadingStatus: Int]
    ) -> Int {
        switch filter {
        case .all:
            return mangaItems.count
        case .status(let status):
            return countsByStatus[status, default: 0]
        }
    }

    // MARK: - Private Methods

    private func weeklyAddedSummary(count: Int, filterTitle: String?) -> String {
        switch filterTitle {
        case .some(let title):
            return "最近 7 天新增 \(count) 筆\(title)收藏"
        case .none:
            return "最近 7 天新增 \(count) 筆收藏"
        }
    }
}

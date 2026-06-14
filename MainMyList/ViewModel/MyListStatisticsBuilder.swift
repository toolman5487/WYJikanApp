//
//  MyListStatisticsBuilder.swift
//  WYJikanApp
//

import Foundation

struct MyListStatisticsBuildResult {
    let statistics: MyListStatistics
    let filteredItems: [MyListCollectionItem]
    let animeCount: Int
    let mangaCount: Int
    let weeklyAddedCount: Int
    let weeklyAnimeAddedCount: Int
    let weeklyMangaAddedCount: Int
}

struct MyListStatisticsBuilder {

    // MARK: - Build

    func build(
        from items: [MyListCollectionItem],
        selectedFilter: MyListFilter
    ) -> MyListStatisticsBuildResult {
        let weekStartDate = weekStartDate()
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
        let selectedAnalysis = selectedGenreAnalysis(
            selectedFilter: selectedFilter,
            allAnalysis: allAnalysis,
            animeAnalysis: animeAnalysis,
            mangaAnalysis: mangaAnalysis
        )
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

        return MyListStatisticsBuildResult(
            statistics: statistics,
            filteredItems: filteredItems,
            animeCount: animeCount,
            mangaCount: mangaCount,
            weeklyAddedCount: weeklyAddedCount,
            weeklyAnimeAddedCount: weeklyAnimeAddedCount,
            weeklyMangaAddedCount: weeklyMangaAddedCount
        )
    }

    func emptyStatistics(selectedFilter: MyListFilter) -> MyListStatistics {
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
        let selectedAnalysis = selectedGenreAnalysis(
            selectedFilter: selectedFilter,
            allAnalysis: emptyAllAnalysis,
            animeAnalysis: emptyAnimeAnalysis,
            mangaAnalysis: emptyMangaAnalysis
        )

        return MyListStatistics(
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
    }

    // MARK: - Genre Analysis

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

    private func selectedGenreAnalysis(
        selectedFilter: MyListFilter,
        allAnalysis: MyListGenreAnalysis,
        animeAnalysis: MyListGenreAnalysis,
        mangaAnalysis: MyListGenreAnalysis
    ) -> MyListGenreAnalysis {
        switch selectedFilter {
        case .all:
            return allAnalysis
        case .anime:
            return animeAnalysis
        case .manga:
            return mangaAnalysis
        }
    }

    // MARK: - Format Analysis

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

    // MARK: - Date

    private func weekStartDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))
            ?? calendar.startOfDay(for: now)
    }
}

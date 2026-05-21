//
//  MainMyListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Combine
import Foundation
import OSLog
import SwiftData

@MainActor
final class MainMyListViewModel: ObservableObject {
    struct Presentation {
        enum StatisticsScope: String, CaseIterable, Identifiable {
            case all
            case anime
            case manga

            var id: String { rawValue }

            var title: String {
                switch self {
                case .all:
                    return "全部"
                case .anime:
                    return "動畫"
                case .manga:
                    return "漫畫"
                }
            }
        }

        struct SummaryTile {
            let title: String
            let value: Int
            let iconName: String
            let detail: String
        }

        struct Statistics {
            struct GenreSlice: Identifiable {
                let genreName: String
                let count: Int

                var id: String { genreName }
            }

            struct GenreAnalysis: Identifiable {
                let scope: StatisticsScope
                let itemCount: Int
                let genreSlices: [GenreSlice]
                let missingGenreItemCount: Int

                var id: StatisticsScope { scope }
                var topGenreSlice: GenreSlice? { genreSlices.first }
            }

            let totalCount: Int
            let animeCount: Int
            let mangaCount: Int
            let allAnalysis: GenreAnalysis
            let animeAnalysis: GenreAnalysis
            let mangaAnalysis: GenreAnalysis
            let selectedAnalysis: GenreAnalysis
        }

        let filteredItems: [MyListCollectionItem]
        let statistics: Statistics
        let summaryTile: SummaryTile
    }

    enum Filter: String, CaseIterable, Identifiable {
        case all
        case anime
        case manga

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "全部"
            case .anime: return "動畫"
            case .manga: return "漫畫"
            }
        }

        var mediaKind: MyListMediaKind? {
            switch self {
            case .all: return nil
            case .anime: return .anime
            case .manga: return .manga
            }
        }
    }

    @Published var selectedFilter: Filter = .all
    private let favoriteRepository: any FavoriteRepository

    init(favoriteRepository: any FavoriteRepository = SwiftDataFavoriteRepository.shared) {
        self.favoriteRepository = favoriteRepository
    }

    func makePresentation(from items: [MyListCollectionItem]) -> Presentation {
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
        let selectedAnalysis: Presentation.Statistics.GenreAnalysis
        switch selectedFilter {
        case .all:
            selectedAnalysis = allAnalysis
        case .anime:
            selectedAnalysis = animeAnalysis
        case .manga:
            selectedAnalysis = mangaAnalysis
        }

        let statistics = Presentation.Statistics(
            totalCount: items.count,
            animeCount: animeCount,
            mangaCount: mangaCount,
            allAnalysis: allAnalysis,
            animeAnalysis: animeAnalysis,
            mangaAnalysis: mangaAnalysis,
            selectedAnalysis: selectedAnalysis
        )

        let summaryTile: Presentation.SummaryTile
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
                    filterTitle: Filter.anime.title
                )
            )
        case .manga:
            summaryTile = .init(
                title: "漫畫收藏",
                value: mangaCount,
                iconName: MyListMediaKind.manga.iconName,
                detail: weeklyAddedSummary(
                    count: weeklyMangaAddedCount,
                    filterTitle: Filter.manga.title
                )
            )
        }

        return Presentation(
            filteredItems: filteredItems,
            statistics: statistics,
            summaryTile: summaryTile
        )
    }

    func remove(_ item: MyListCollectionItem, from modelContext: ModelContext) {
        do {
            try favoriteRepository.remove(item, from: modelContext)
        } catch {
            AppLogger.persistence.error("MyList delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func emptyTitle(for filter: Filter) -> String {
        filter == .all ? "還沒有收藏" : "還沒有收藏\(filter.title)"
    }

    private func weeklyAddedSummary(count: Int, filterTitle: String?) -> String {
        switch filterTitle {
        case .some(let title):
            return "最近 7 天新增 \(count) 筆\(title)收藏"
        case .none:
            return "最近 7 天新增 \(count) 筆收藏"
        }
    }

    private func makeGenreAnalysis(
        from items: [MyListCollectionItem],
        scope: Presentation.StatisticsScope
    ) -> Presentation.Statistics.GenreAnalysis {
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
                Presentation.Statistics.GenreSlice(genreName: genreName, count: count)
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.genreName.localizedStandardCompare(rhs.genreName) == .orderedAscending
                }
                return lhs.count > rhs.count
            }

        return Presentation.Statistics.GenreAnalysis(
            scope: scope,
            itemCount: items.count,
            genreSlices: Array(genreSlices.prefix(6)),
            missingGenreItemCount: missingGenreItemCount
        )
    }
}

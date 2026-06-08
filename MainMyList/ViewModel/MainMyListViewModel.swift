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

            struct FormatSlice: Identifiable {
                let title: String
                let iconName: String
                let count: Int

                var id: String { title }
            }

            struct GenreAnalysis: Identifiable {
                let scope: StatisticsScope
                let itemCount: Int
                let genreSlices: [GenreSlice]
                let missingGenreItemCount: Int

                var id: StatisticsScope { scope }
                var topGenreSlice: GenreSlice? { genreSlices.first }
            }

            struct FormatAnalysis {
                let scope: StatisticsScope
                let itemCount: Int
                let formatSlices: [FormatSlice]
                let missingTypeItemCount: Int

                var topFormatSlice: FormatSlice? { formatSlices.first }
            }

            let totalCount: Int
            let animeCount: Int
            let mangaCount: Int
            let allAnalysis: GenreAnalysis
            let animeAnalysis: GenreAnalysis
            let mangaAnalysis: GenreAnalysis
            let selectedAnalysis: GenreAnalysis
            let formatAnalysis: FormatAnalysis
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

    @Published private(set) var presentation: Presentation
    @Published var selectedFilter: Filter = .all {
        didSet {
            guard selectedFilter != oldValue else { return }
            rebuildPresentationFromCachedItems()
        }
    }

    private let favoriteRepository: any FavoriteRepository
    private var cachedItems: [MyListCollectionItem] = []

    init(favoriteRepository: any FavoriteRepository = SwiftDataFavoriteRepository.shared) {
        self.favoriteRepository = favoriteRepository
        self.presentation = Self.emptyPresentation(selectedFilter: .all)
    }

    func refreshPresentation(from items: [MyListCollectionItem]) {
        cachedItems = items
        rebuildPresentationFromCachedItems()
    }

    private func rebuildPresentationFromCachedItems() {
        presentation = makePresentation(
            from: cachedItems,
            selectedFilter: selectedFilter
        )
    }

    private func makePresentation(
        from items: [MyListCollectionItem],
        selectedFilter: Filter
    ) -> Presentation {
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
        let formatAnalysis = makeFormatAnalysis(
            from: filteredItems,
            scope: selectedAnalysis.scope
        )

        let statistics = Presentation.Statistics(
            totalCount: items.count,
            animeCount: animeCount,
            mangaCount: mangaCount,
            allAnalysis: allAnalysis,
            animeAnalysis: animeAnalysis,
            mangaAnalysis: mangaAnalysis,
            selectedAnalysis: selectedAnalysis,
            formatAnalysis: formatAnalysis
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

    private static func emptyPresentation(selectedFilter: Filter) -> Presentation {
        let emptyAllAnalysis = Presentation.Statistics.GenreAnalysis(
            scope: .all,
            itemCount: 0,
            genreSlices: [],
            missingGenreItemCount: 0
        )
        let emptyAnimeAnalysis = Presentation.Statistics.GenreAnalysis(
            scope: .anime,
            itemCount: 0,
            genreSlices: [],
            missingGenreItemCount: 0
        )
        let emptyMangaAnalysis = Presentation.Statistics.GenreAnalysis(
            scope: .manga,
            itemCount: 0,
            genreSlices: [],
            missingGenreItemCount: 0
        )

        let selectedAnalysis: Presentation.Statistics.GenreAnalysis
        let summaryTile: Presentation.SummaryTile
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

        let statistics = Presentation.Statistics(
            totalCount: 0,
            animeCount: 0,
            mangaCount: 0,
            allAnalysis: emptyAllAnalysis,
            animeAnalysis: emptyAnimeAnalysis,
            mangaAnalysis: emptyMangaAnalysis,
            selectedAnalysis: selectedAnalysis,
            formatAnalysis: Presentation.Statistics.FormatAnalysis(
                scope: selectedAnalysis.scope,
                itemCount: 0,
                formatSlices: [],
                missingTypeItemCount: 0
            )
        )

        return Presentation(
            filteredItems: [],
            statistics: statistics,
            summaryTile: summaryTile
        )
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

    private func makeFormatAnalysis(
        from items: [MyListCollectionItem],
        scope: Presentation.StatisticsScope
    ) -> Presentation.Statistics.FormatAnalysis {
        var formatCounts: [String: Int] = [:]
        var missingTypeItemCount = 0

        for item in items {
            guard let format = Self.formatDisplayItem(
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
                Presentation.Statistics.FormatSlice(
                    title: title,
                    iconName: Self.iconName(forFormatTitle: title),
                    count: count
                )
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }
                return lhs.count > rhs.count
            }

        return Presentation.Statistics.FormatAnalysis(
            scope: scope,
            itemCount: items.count,
            formatSlices: Array(formatSlices.prefix(6)),
            missingTypeItemCount: missingTypeItemCount
        )
    }

    private static func formatDisplayItem(
        type: String?,
        mediaKind: MyListMediaKind
    ) -> (title: String, iconName: String)? {
        guard let type else { return nil }
        let normalizedType = type.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedType.isEmpty else { return nil }

        switch mediaKind {
        case .anime:
            return animeFormatDisplayItem(type: normalizedType)
        case .manga:
            return mangaFormatDisplayItem(type: normalizedType)
        }
    }

    private static func animeFormatDisplayItem(type: String) -> (title: String, iconName: String) {
        switch type.lowercased() {
        case "tv":
            return ("電視動畫", "tv.fill")
        case "movie":
            return ("電影", "film.fill")
        case "ova":
            return ("OVA", "opticaldisc.fill")
        case "ona":
            return ("ONA", "play.rectangle.on.rectangle.fill")
        case "special", "tv special":
            return ("特別篇", "sparkles.tv.fill")
        case "music":
            return ("音樂", "music.note")
        default:
            return (type, MyListMediaKind.anime.iconName)
        }
    }

    private static func mangaFormatDisplayItem(type: String) -> (title: String, iconName: String) {
        switch type.lowercased() {
        case "manga":
            return ("漫畫", "book.closed.fill")
        case "manhwa":
            return ("韓漫", "book.pages.fill")
        case "manhua":
            return ("華語漫畫", "books.vertical.fill")
        case "novel":
            return ("小說", "text.book.closed.fill")
        case "light novel":
            return ("輕小說", "book.fill")
        case "one-shot":
            return ("短篇", "doc.text.fill")
        case "doujinshi":
            return ("同人誌", "person.2.fill")
        default:
            return (type, MyListMediaKind.manga.iconName)
        }
    }

    private static func iconName(forFormatTitle title: String) -> String {
        switch title {
        case "電視動畫":
            return "tv.fill"
        case "電影":
            return "film.fill"
        case "OVA":
            return "opticaldisc.fill"
        case "ONA":
            return "play.rectangle.on.rectangle.fill"
        case "特別篇":
            return "sparkles.tv.fill"
        case "音樂":
            return "music.note"
        case "漫畫":
            return "book.closed.fill"
        case "韓漫":
            return "book.pages.fill"
        case "華語漫畫":
            return "books.vertical.fill"
        case "小說":
            return "text.book.closed.fill"
        case "輕小說":
            return "book.fill"
        case "短篇":
            return "doc.text.fill"
        case "同人誌":
            return "person.2.fill"
        default:
            return "square.grid.2x2.fill"
        }
    }
}

//
//  HomeTrendingAnimeListPresentationBuilder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Foundation

// MARK: - HomeTrendingAnimeListPresentationBuilder

struct HomeTrendingAnimeListPresentationBuilder {
    private let textFormatter = MainHomeMediaTextFormatter()

    // MARK: - Public Methods

    func headerContent(
        sort: HomeTrendingAnimeListSort,
        loadedCount: Int
    ) -> HomeTrendingAnimeListHeaderContent {
        HomeTrendingAnimeListHeaderContent(
            title: headerTitle(for: sort),
            subtitle: headerSubtitle(for: sort),
            loadedCountText: "已載入 \(loadedCount) 部"
        )
    }

    func sections(
        from items: [HomeTrendingAnimeListItem],
        sort: HomeTrendingAnimeListSort
    ) -> [HomeTrendingAnimeListSectionContent] {
        let definitions = sectionDefinitions(for: sort)
        return definitions.compactMap { definition in
            let sectionItems = items[safe: definition.range]
            guard !sectionItems.isEmpty else { return nil }
            return HomeTrendingAnimeListSectionContent(
                id: definition.id,
                title: definition.title,
                subtitle: definition.subtitle,
                countText: "\(sectionItems.count) 部",
                items: sectionItems
            )
        }
    }

    func sortedItems(
        _ items: [HomeTrendingAnimeListItem],
        sort: HomeTrendingAnimeListSort
    ) -> [HomeTrendingAnimeListItem] {
        switch sort {
        case .apiDefault:
            return items
        case .rank:
            return items.sorted { lhs, rhs in
                compareOptionalAscending(lhs.rank, rhs.rank, fallbackTitleLeft: lhs.title, fallbackTitleRight: rhs.title)
            }
        case .popularity:
            return items.sorted { lhs, rhs in
                let lhsValue = popularityValue(from: lhs.popularityText)
                let rhsValue = popularityValue(from: rhs.popularityText)
                return compareOptionalAscending(lhsValue, rhsValue, fallbackTitleLeft: lhs.title, fallbackTitleRight: rhs.title)
            }
        case .score:
            return items.sorted { lhs, rhs in
                let lhsValue = Double(lhs.scoreText ?? "")
                let rhsValue = Double(rhs.scoreText ?? "")
                return compareOptionalDescending(lhsValue, rhsValue, fallbackTitleLeft: lhs.title, fallbackTitleRight: rhs.title)
            }
        }
    }

    func item(from dto: HomeTrendingAnimeListDTO) -> HomeTrendingAnimeListItem? {
        HomeTrendingAnimeListItem(
            id: dto.id,
            title: textFormatter.preferredTitle(
                japanese: dto.titleJapanese,
                english: dto.titleEnglish,
                fallback: dto.title
            ),
            typeText: textFormatter.animeTypeText(dto.type),
            scoreText: textFormatter.scoreText(dto.score, precision: 2),
            rank: dto.rank,
            popularityText: textFormatter.popularityText(dto.popularity),
            membersText: textFormatter.memberCountText(dto.members),
            episodeText: textFormatter.episodeText(dto.episodes),
            statusText: textFormatter.animeStatusText(dto.status),
            seasonText: textFormatter.animeSeasonText(season: dto.season, year: dto.year),
            synopsisPreview: textFormatter.synopsisPreview(dto.synopsis, limit: 110),
            imageURL: posterURL(from: dto)
        )
    }
}

// MARK: - Private Methods

private extension HomeTrendingAnimeListPresentationBuilder {
    func headerTitle(for sort: HomeTrendingAnimeListSort) -> String {
        switch sort {
        case .apiDefault:
            return "本週熱門動畫"
        case .rank:
            return "排名動畫榜"
        case .popularity:
            return "人氣動畫榜"
        case .score:
            return "高分動畫榜"
        }
    }

    func headerSubtitle(for sort: HomeTrendingAnimeListSort) -> String {
        switch sort {
        case .apiDefault:
            return "整理現在最多人關注的動畫作品，先看榜首，再一路往下挖熱門清單。"
        case .rank:
            return "從榜單名次一路往下看，先鎖定站上前段班、討論度最高的動畫作品。"
        case .popularity:
            return "依人氣熱度重新整理，適合先找現在最多人追、最常被提起的熱門作品。"
        case .score:
            return "把評價表現突出的作品拉到前面，想先看口碑穩、分數亮眼的動畫可以從這裡開始。"
        }
    }

    func sectionDefinitions(for sort: HomeTrendingAnimeListSort) -> [TrendingSectionDefinition] {
        _ = sort
        return [
            TrendingSectionDefinition(id: "top3", title: "TOP 3", subtitle: "", range: 0..<3),
            TrendingSectionDefinition(id: "top10", title: "TOP 10", subtitle: "", range: 3..<10),
            TrendingSectionDefinition(id: "top25", title: "TOP 25", subtitle: "", range: 10..<25),
            TrendingSectionDefinition(id: "top25plus", title: "TOP 25+", subtitle: "", range: 25..<Int.max)
        ]
    }

    func compareOptionalAscending<T: Comparable>(
        _ lhs: T?,
        _ rhs: T?,
        fallbackTitleLeft: String,
        fallbackTitleRight: String
    ) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            if lhs == rhs { return fallbackTitleLeft < fallbackTitleRight }
            return lhs < rhs
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return fallbackTitleLeft < fallbackTitleRight
        }
    }

    func compareOptionalDescending<T: Comparable>(
        _ lhs: T?,
        _ rhs: T?,
        fallbackTitleLeft: String,
        fallbackTitleRight: String
    ) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            if lhs == rhs { return fallbackTitleLeft < fallbackTitleRight }
            return lhs > rhs
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return fallbackTitleLeft < fallbackTitleRight
        }
    }

    func popularityValue(from text: String?) -> Int? {
        guard let text else { return nil }
        return Int(text.replacingOccurrences(of: "人氣 #", with: ""))
    }

    func posterURL(from dto: HomeTrendingAnimeListDTO) -> URL? {
        JikanImageURLResolver.url(from: dto.images, tier: .poster)
    }

    struct TrendingSectionDefinition {
        let id: String
        let title: String
        let subtitle: String
        let range: Range<Int>
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe range: Range<Int>) -> [Element] {
        guard !isEmpty else { return [] }
        let lowerBound = Swift.max(0, range.lowerBound)
        let upperBound = Swift.min(count, range.upperBound)
        guard lowerBound < upperBound else { return [] }
        return Array(self[lowerBound..<upperBound])
    }
}

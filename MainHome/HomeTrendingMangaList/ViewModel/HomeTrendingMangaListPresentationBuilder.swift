//
//  HomeTrendingMangaListPresentationBuilder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Foundation

// MARK: - HomeTrendingMangaListPresentationBuilder

struct HomeTrendingMangaListPresentationBuilder {

    // MARK: - Public Methods

    func headerTitle(
        sort: HomeTrendingMangaListSort,
        format: HomeTrendingMangaListFormat
    ) -> String {
        let baseTitle: String
        switch sort {
        case .apiDefault:
            baseTitle = "本週熱門漫畫"
        case .rank:
            baseTitle = "排名漫畫榜"
        case .popularity:
            baseTitle = "人氣漫畫榜"
        case .score:
            baseTitle = "高分漫畫榜"
        }

        switch format {
        case .all:
            return baseTitle
        default:
            return "\(format.title)\(baseTitle)"
        }
    }

    func headerSubtitle(
        sort: HomeTrendingMangaListSort,
        format: HomeTrendingMangaListFormat
    ) -> String {
        switch (sort, format) {
        case (.apiDefault, .all):
            return "把現在榜上最受關注的漫畫一次展開，先看榜首，再慢慢往下挖完整熱門清單。"
        case (.rank, .all):
            return "從榜單名次一路往下看，先鎖定站上前段班、討論度高的漫畫作品。"
        case (.popularity, .all):
            return "依人氣熱度重新整理，適合先找現在最多人追、最常被提起的熱門作品。"
        case (.score, .all):
            return "把評價表現突出的作品拉到前面，想先看口碑穩、分數亮眼的漫畫可以從這裡開始。"
        case (.apiDefault, _):
            return "整理目前最受關注的\(format.title)作品，讓你快速找到這個類型裡最值得先看的熱門選擇。"
        case (.rank, _):
            return "從名次往下看這批\(format.title)作品，先鎖定榜上前段班與討論度高的焦點名單。"
        case (.popularity, _):
            return "依人氣熱度重新整理這批\(format.title)作品，適合先找現在最多人追的熱門選擇。"
        case (.score, _):
            return "把高評價的\(format.title)作品拉到前面，想先看口碑穩、分數亮眼的類型可以從這裡開始。"
        }
    }

    func presentedItems(
        from items: [MangaCategoryItemDTO],
        sort: HomeTrendingMangaListSort,
        format: HomeTrendingMangaListFormat
    ) -> [MangaCategoryItemDTO] {
        let filtered = items.filter { item in
            format.matches(type: item.type)
        }

        switch sort {
        case .apiDefault:
            return filtered
        case .rank:
            return filtered.sorted { lhs, rhs in
                compareOptionalAscending(
                    lhs.rank,
                    rhs.rank,
                    fallbackTitleLeft: lhs.displayTitle,
                    fallbackTitleRight: rhs.displayTitle
                )
            }
        case .popularity:
            return filtered.sorted { lhs, rhs in
                compareOptionalAscending(
                    lhs.popularity,
                    rhs.popularity,
                    fallbackTitleLeft: lhs.displayTitle,
                    fallbackTitleRight: rhs.displayTitle
                )
            }
        case .score:
            return filtered.sorted { lhs, rhs in
                compareOptionalDescending(
                    lhs.score,
                    rhs.score,
                    fallbackTitleLeft: lhs.displayTitle,
                    fallbackTitleRight: rhs.displayTitle
                )
            }
        }
    }
}

// MARK: - Private Methods

private extension HomeTrendingMangaListPresentationBuilder {
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
}

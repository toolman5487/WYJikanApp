//
//  HomeWatchFeed.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Foundation

// MARK: - HomeWatchEpisodeFeed

nonisolated enum HomeWatchEpisodeFeed: Sendable {
    case latest
    case popular
}

// MARK: - HomeWatchPromoFeed

nonisolated enum HomeWatchPromoFeed: Sendable {
    case latest
    case popular
}

// MARK: - HomeWatchContentKind

nonisolated enum HomeWatchContentKind: Sendable {
    case episode
    case promo

    var title: String {
        switch self {
        case .episode:
            return "集數"
        case .promo:
            return "預告"
        }
    }
}

// MARK: - HomeWatchFeedKind

nonisolated enum HomeWatchFeedKind: String, CaseIterable, Identifiable, Sendable {
    case latestEpisodes
    case popularEpisodes
    case latestPromos
    case popularPromos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latestEpisodes:
            return "最新集數"
        case .popularEpisodes:
            return "熱門集數"
        case .latestPromos:
            return "最新預告"
        case .popularPromos:
            return "熱門預告"
        }
    }

    var subtitle: String {
        switch self {
        case .latestEpisodes:
            return "追蹤最近上架的可觀看動畫集數。"
        case .popularEpisodes:
            return "整理目前最多人關注的可觀看集數。"
        case .latestPromos:
            return "瀏覽最新公開的宣傳影片、廣告與預告片。"
        case .popularPromos:
            return "查看近期最常被觀看的動畫預告。"
        }
    }

    var systemImageName: String {
        switch self {
        case .latestEpisodes:
            return "play.rectangle.on.rectangle"
        case .popularEpisodes:
            return "flame"
        case .latestPromos:
            return "film"
        case .popularPromos:
            return "play.circle"
        }
    }

    var contentKind: HomeWatchContentKind {
        switch self {
        case .latestEpisodes:
            return .episode
        case .popularEpisodes:
            return .episode
        case .latestPromos:
            return .promo
        case .popularPromos:
            return .promo
        }
    }

    var episodeFeed: HomeWatchEpisodeFeed? {
        switch self {
        case .latestEpisodes:
            return .latest
        case .popularEpisodes:
            return .popular
        case .latestPromos:
            return nil
        case .popularPromos:
            return nil
        }
    }

    var promoFeed: HomeWatchPromoFeed? {
        switch self {
        case .latestPromos:
            return .latest
        case .popularPromos:
            return .popular
        case .latestEpisodes:
            return nil
        case .popularEpisodes:
            return nil
        }
    }
}

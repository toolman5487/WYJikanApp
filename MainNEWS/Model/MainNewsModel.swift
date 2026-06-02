//
//  MainNewsModel.swift
//  WYJikanApp
//

import Foundation

nonisolated enum MainNewsSource: String, CaseIterable, Identifiable, Sendable {
    case animeNewsNetwork
    case myAnimeList
    case crunchyroll

    nonisolated var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .animeNewsNetwork:
            return "Anime News Network"
        case .myAnimeList:
            return "MyAnimeList"
        case .crunchyroll:
            return "Crunchyroll News"
        }
    }

    nonisolated var feedURLString: String {
        switch self {
        case .animeNewsNetwork:
            return "https://www.animenewsnetwork.com/all/rss.xml"
        case .myAnimeList:
            return "https://myanimelist.net/rss/news.xml"
        case .crunchyroll:
            return "https://cr-news-api-service.prd.crunchyrollsvc.com/v1/en-US/rss"
        }
    }
}

nonisolated struct MainNewsFeed: Hashable, Sendable {
    let updatedAt: Date
    let articles: [MainNewsArticle]
}

nonisolated struct MainNewsArticle: Identifiable, Hashable, Sendable {
    let id: String
    let source: MainNewsSource
    let title: String
    let summary: String?
    let linkURL: URL
    let imageURL: URL?
    let publishedAt: Date?
    let author: String?
    let categories: [String]
}

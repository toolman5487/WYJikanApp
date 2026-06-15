//
//  TrendingMangaModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Foundation

// MARK: - Presentation


nonisolated struct HomeTrendingMangaCardItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let type: String?
    let score: Double?
    let rank: Int?
    let imageURL: URL
}

// MARK: - Response (Jikan /top/manga)

nonisolated struct HomeTrendingMangaResponse: Codable, Sendable {
    let data: [HomeTrendingMangaDTO]
}

nonisolated struct HomeTrendingMangaDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let type: String?
    let score: Double?
    let rank: Int?
    let images: AnimeImagesDTO?

    var id: Int { malId }
    var imgUrl: String? {
        JikanImageURLResolver.urlString(from: images, tier: .card)
    }
}

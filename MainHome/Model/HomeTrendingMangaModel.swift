//
//  TrendingMangaModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Foundation

// MARK: - Presentation

struct HomeTrendingMangaCardItem: Identifiable, Hashable, Sendable {
    let id: Int
    let rank: Int?
    let imageURL: URL
}

// MARK: - Response (Jikan /top/manga)

struct HomeTrendingMangaResponse: Codable {
    let data: [HomeTrendingMangaDTO]
}

struct HomeTrendingMangaDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let rank: Int?
    let images: AnimeImagesDTO?

    var id: Int { malId }
    var imgUrl: String? {
        images?.jpg?.largeImageUrl ??
        images?.webp?.largeImageUrl ??
        images?.jpg?.imageUrl ??
        images?.webp?.imageUrl
    }
}

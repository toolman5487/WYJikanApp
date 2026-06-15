//
//  HeroBannerModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Foundation

// MARK: - Presentation


nonisolated struct BannerItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let type: String?
    let score: Double?
    let imageURL: URL
}

// MARK: - Response

nonisolated struct HeroBannerResponse: Codable, Sendable {
    let data: [HeroBannerAnimeDTO]
}

// MARK: - Anime

nonisolated struct HeroBannerAnimeDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let type: String?
    let score: Double?
    let images: AnimeImagesDTO?

    var id: Int { malId }
}

// MARK: - Images

nonisolated struct AnimeImagesDTO: Codable, Hashable, Sendable {
    let jpg: AnimeImageVariantDTO?
    let webp: AnimeImageVariantDTO?
}

nonisolated struct AnimeImageVariantDTO: Codable, Hashable, Sendable {
    let imageUrl: String?
    let smallImageUrl: String?
    let largeImageUrl: String?
}

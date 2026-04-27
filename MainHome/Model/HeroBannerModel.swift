//
//  HeroBannerModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Foundation

// MARK: - Presentation

struct BannerItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let type: String?
    let score: Double?
    let imageURL: URL
}

// MARK: - Response

struct HeroBannerResponse: Codable {
    let data: [HeroBannerAnimeDTO]
}

// MARK: - Anime

struct HeroBannerAnimeDTO: Codable, Identifiable, Hashable {
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

struct AnimeImagesDTO: Codable, Hashable {
    let jpg: AnimeImageVariantDTO?
    let webp: AnimeImageVariantDTO?
}

struct AnimeImageVariantDTO: Codable, Hashable {
    let imageUrl: String?
    let smallImageUrl: String?
    let largeImageUrl: String?
}

//
//  HomeTrendingModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Foundation

// MARK: - Response (Jikan /top/anime)

struct HomeTrendingAnimeResponse: Codable {
    let data: [HomeTrendingAnimeDTO]
}

struct HomeTrendingAnimeDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let rank: Int?
    let images: AnimeImagesDTO?
    var id: Int { malId }
}

// MARK: - Presentation

struct HomeTrendingAnimeCardItem: Identifiable, Hashable, Sendable {
    let id: Int
    let rank: Int?
    let imageURL: URL
}

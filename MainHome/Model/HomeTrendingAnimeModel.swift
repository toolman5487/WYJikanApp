//
//  HomeTrendingModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Foundation

// MARK: - Response (Jikan /top/anime)

nonisolated struct HomeTrendingAnimeResponse: Codable, Sendable {
    let data: [HomeTrendingAnimeDTO]
}

nonisolated struct HomeTrendingAnimeDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let type: String?
    let score: Double?
    let rank: Int?
    let images: AnimeImagesDTO?
    var id: Int { malId }
}

// MARK: - Presentation

nonisolated struct HomeTrendingAnimeCardItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let type: String?
    let score: Double?
    let rank: Int?
    let imageURL: URL
}

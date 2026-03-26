//
//  HomeTrendingModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Foundation

// MARK: - Response (Jikan /top/anime)

struct HomeTrendingResponse: Codable {
    let data: [HomeTrendingDTO]
}

struct HomeTrendingDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let rank: Int?
    let images: AnimeImagesDTO?
    var id: Int { malId }
}

// MARK: - Presentation

struct HomeTrendingCardItem: Identifiable, Hashable, Sendable {
    let id: Int
    let rank: Int?
    let imageURL: URL
}

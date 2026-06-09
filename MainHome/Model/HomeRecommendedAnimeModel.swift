//
//  HomeRecommendedAnimeModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/27.
//

import Foundation

nonisolated struct HomeRecommendedAnimeResponse: Codable, Sendable {
    let data: [HomeRecommendedAnimeDTO]
}

nonisolated struct HomeRecommendedAnimeDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: String
    let entry: [HomeRecommendedAnimeEntryDTO]
    let content: String?
    let user: HomeRecommendedAnimeUserDTO?

    var id: String { malId }
}

nonisolated struct HomeRecommendedAnimeEntryDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let title: String?
    let images: AnimeImagesDTO?

    var id: Int { malId }
}

nonisolated struct HomeRecommendedAnimeUserDTO: Codable, Hashable, Sendable {
    let username: String?
}

nonisolated struct HomeRecommendedAnimeCardItem: Identifiable, Hashable, Sendable {
    let id: String
    let sourceTitle: String
    let recommendedTitle: String
    let username: String?
    let detailMalId: Int
    let imageURL: URL
}

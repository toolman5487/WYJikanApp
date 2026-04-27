//
//  HomeRecommendedAnimeModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/27.
//

import Foundation

struct HomeRecommendedAnimeResponse: Codable {
    let data: [HomeRecommendedAnimeDTO]
}

struct HomeRecommendedAnimeDTO: Codable, Identifiable, Hashable {
    let malId: String
    let entry: [HomeRecommendedAnimeEntryDTO]
    let content: String?
    let user: HomeRecommendedAnimeUserDTO?

    var id: String { malId }
}

struct HomeRecommendedAnimeEntryDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let title: String?
    let images: AnimeImagesDTO?

    var id: Int { malId }
}

struct HomeRecommendedAnimeUserDTO: Codable, Hashable {
    let username: String?
}

struct HomeRecommendedAnimeCardItem: Identifiable, Hashable, Sendable {
    let id: String
    let sourceTitle: String
    let recommendedTitle: String
    let username: String?
    let detailMalId: Int
    let imageURL: URL
}

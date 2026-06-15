//
//  HomeWatchModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Foundation

// MARK: - Response


nonisolated struct HomeWatchPromosResponse: Codable, Sendable {
    let pagination: HomeWatchPaginationDTO?
    let data: [HomeWatchPromoDTO]
}

nonisolated struct HomeWatchEpisodesResponse: Codable, Sendable {
    let pagination: HomeWatchPaginationDTO?
    let data: [HomeWatchEpisodeGroupDTO]
}

nonisolated struct HomeWatchPaginationDTO: Codable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

nonisolated struct HomeWatchPromoDTO: Codable, Hashable, Sendable {
    let title: String?
    let entry: HomeWatchEntryDTO?
    let trailer: HomeWatchTrailerDTO?
}

nonisolated struct HomeWatchEpisodeGroupDTO: Codable, Hashable, Sendable {
    let entry: HomeWatchEntryDTO?
    let episodes: [HomeWatchEpisodeDTO]
    let regionLocked: Bool?
}

nonisolated struct HomeWatchEntryDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?

    var id: Int { malId }
}

nonisolated struct HomeWatchEpisodeDTO: Codable, Hashable, Sendable {
    let malId: Int?
    let url: String?
    let title: String?
    let premium: Bool?
}

nonisolated struct HomeWatchTrailerDTO: Codable, Hashable, Sendable {
    let youtubeId: String?
    let url: String?
    let embedUrl: String?
    let images: HomeWatchTrailerImagesDTO?
}

nonisolated struct HomeWatchTrailerImagesDTO: Codable, Hashable, Sendable {
    let imageUrl: String?
    let smallImageUrl: String?
    let mediumImageUrl: String?
    let largeImageUrl: String?
    let maximumImageUrl: String?
}

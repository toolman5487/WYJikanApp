//
//  AnimeReviewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation

// MARK: - Response (Jikan /anime/{id}/reviews)

nonisolated struct AnimeReviewsListResponse: Codable, Sendable {
    let pagination: AnimeReviewsPaginationDTO?
    let data: [AnimeReviewEntryDTO]
}

nonisolated struct AnimeReviewsPaginationDTO: Codable, Sendable {
    let lastVisiblePage: Int?
    let hasNextPage: Bool?
    let currentPage: Int?
}

nonisolated struct AnimeReviewEntryDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let type: String?
    let reactions: AnimeReviewReactionsDTO?
    let date: String?
    let review: String?
    let score: Int?
    let tags: [String]?
    let isSpoiler: Bool?
    let isPreliminary: Bool?
    let episodesWatched: Int?
    let user: AnimeReviewUserDTO?

    var id: Int { malId }
}

nonisolated struct AnimeReviewReactionsDTO: Codable, Hashable, Sendable {
    let overall: Int?
    let nice: Int?
    let loveIt: Int?
    let funny: Int?
    let confusing: Int?
    let informative: Int?
    let wellWritten: Int?
    let creative: Int?
}

nonisolated struct AnimeReviewUserDTO: Codable, Hashable, Sendable {
    let url: String?
    let username: String?
    let images: AnimeImagesDTO?
}

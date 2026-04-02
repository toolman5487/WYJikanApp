//
//  AnimeReviewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation

// MARK: - Response (Jikan /anime/{id}/reviews)

struct AnimeReviewsListResponse: Codable {
    let pagination: AnimeReviewsPaginationDTO?
    let data: [AnimeReviewEntryDTO]
}

struct AnimeReviewsPaginationDTO: Codable {
    let lastVisiblePage: Int?
    let hasNextPage: Bool?
    let currentPage: Int?
}

struct AnimeReviewEntryDTO: Codable, Identifiable, Hashable {
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

struct AnimeReviewReactionsDTO: Codable, Hashable {
    let overall: Int?
    let nice: Int?
    let loveIt: Int?
    let funny: Int?
    let confusing: Int?
    let informative: Int?
    let wellWritten: Int?
    let creative: Int?
}

struct AnimeReviewUserDTO: Codable, Hashable {
    let url: String?
    let username: String?
    let images: AnimeImagesDTO?
}

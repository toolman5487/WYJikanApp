//
//  MangaReviewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Foundation

// MARK: - Response (Jikan /manga/{id}/reviews)

struct MangaReviewsListResponse: Codable {
    let pagination: AnimeReviewsPaginationDTO?
    let data: [MangaReviewEntryDTO]
}

struct MangaReviewEntryDTO: Codable, Identifiable, Hashable {
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
    let chaptersRead: Int?
    let user: AnimeReviewUserDTO?

    var id: Int { malId }
}

//
//  HomeTodayAnimeModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Foundation

// MARK: - Response (Jikan /schedules/{day})

struct HomeTodayAnimeResponse: Codable {
    let data: [HomeTodayAnimeDTO]
}

struct HomeTodayAnimeDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let type: String?
    let score: Double?
    let images: AnimeImagesDTO?
    var id: Int { malId }
}

// MARK: - Presentation

struct HomeTodayAnimeCardItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let type: String?
    let score: Double?
    let imageURL: URL
}

//
//  AnimeListResponseModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation

// MARK: - Genre List Response

nonisolated struct AnimeGenreListResponse: Codable, Sendable {
    let data: [AnimeListGenreDTO]
}

// MARK: - Anime List Response

nonisolated struct AnimeListResponse: Codable, Sendable {
    let data: [AnimeListRandomDTO]
}

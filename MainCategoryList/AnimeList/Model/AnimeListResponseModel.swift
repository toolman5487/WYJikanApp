//
//  AnimeListResponseModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation

// MARK: - Genre List Response

struct AnimeGenreListResponse: Codable {
    let data: [AnimeListGenreDTO]
}

// MARK: - Anime List Response

struct AnimeListResponse: Codable {
    let data: [AnimeListRandomDTO]
}

// MARK: - Random Anime Response

struct AnimeListRandomResponse: Codable {
    let data: AnimeListRandomDTO
}

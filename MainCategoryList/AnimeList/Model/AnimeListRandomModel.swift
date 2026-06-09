//
//  AnimeListRandomModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/9.
//

import Foundation

// MARK: - Random Anime Item

nonisolated struct AnimeListRandomDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let synopsis: String?
    let type: String?
    let score: Double?
    let rank: Int?
    let popularity: Int?
    let members: Int?
    let episodes: Int?
    let images: AnimeListImagesDTO?
    let genres: [AnimeListGenreDTO]?

    var id: Int { malId }
}

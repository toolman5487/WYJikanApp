//
//  MangaDetailModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import Foundation

// MARK: - Response (Jikan /manga/{id})

struct MangaDetailResponse: Codable {
    let data: MangaDetailDTO
}

// MARK: - Manga detail

struct MangaDetailDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let approved: Bool?
    let titles: [AnimeTitleEntryDTO]?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let titleSynonyms: [String]?
    let type: String?
    let chapters: Int?
    let volumes: Int?
    let status: String?
    let publishing: Bool?
    let published: AnimeAiredDTO?
    let score: Double?
    let scored: Double?
    let scoredBy: Int?
    let rank: Int?
    let popularity: Int?
    let members: Int?
    let favorites: Int?
    let synopsis: String?
    let background: String?
    let authors: [AnimeRelatedEntityDTO]?
    let serializations: [AnimeRelatedEntityDTO]?
    let genres: [AnimeRelatedEntityDTO]?
    let explicitGenres: [AnimeRelatedEntityDTO]?
    let themes: [AnimeRelatedEntityDTO]?
    let demographics: [AnimeRelatedEntityDTO]?

    var id: Int { malId }
}

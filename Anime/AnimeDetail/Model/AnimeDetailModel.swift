//
//  AnimeDetailModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

// MARK: - Response (Jikan /anime/{id})

struct AnimeDetailResponse: Codable {
    let data: AnimeDetailDTO
}

// MARK: - Anime detail

struct AnimeDetailDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let trailer: AnimeDetailTrailerDTO?
    let approved: Bool?
    let titles: [AnimeTitleEntryDTO]?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let titleSynonyms: [String]?
    let type: String?
    let source: String?
    let episodes: Int?
    let status: String?
    let airing: Bool?
    let aired: AnimeAiredDTO?
    let duration: String?
    let rating: String?
    let score: Double?
    let scoredBy: Int?
    let rank: Int?
    let popularity: Int?
    let members: Int?
    let favorites: Int?
    let synopsis: String?
    let background: String?
    let season: String?
    let year: Int?
    let broadcast: AnimeBroadcastDTO?
    let producers: [AnimeRelatedEntityDTO]?
    let licensors: [AnimeRelatedEntityDTO]?
    let studios: [AnimeRelatedEntityDTO]?
    let genres: [AnimeRelatedEntityDTO]?
    let explicitGenres: [AnimeRelatedEntityDTO]?
    let themes: [AnimeRelatedEntityDTO]?
    let demographics: [AnimeRelatedEntityDTO]?

    var id: Int { malId }
}

// MARK: - Trailer

struct AnimeDetailTrailerDTO: Codable, Hashable {
    let youtubeId: String?
    let url: String?
    let embedUrl: String?
    let images: AnimeTrailerImagesDTO?
}

struct AnimeTrailerImagesDTO: Codable, Hashable {
    let imageUrl: String?
    let smallImageUrl: String?
    let mediumImageUrl: String?
    let largeImageUrl: String?
    let maximumImageUrl: String?
}

// MARK: - Titles

struct AnimeTitleEntryDTO: Codable, Hashable {
    let type: String?
    let title: String?
}

// MARK: - Aired

struct AnimeAiredDTO: Codable, Hashable {
    let from: String?
    let to: String?
    let prop: AnimeAiredPropDTO?
    let string: String?
}

struct AnimeAiredPropDTO: Codable, Hashable {
    let from: AnimeDatePartsDTO?
    let to: AnimeDatePartsDTO?
}

struct AnimeDatePartsDTO: Codable, Hashable {
    let day: Int?
    let month: Int?
    let year: Int?
}

// MARK: - Broadcast

struct AnimeBroadcastDTO: Codable, Hashable {
    let day: String?
    let time: String?
    let timezone: String?
    let string: String?
}

// MARK: - Producer / studio / genre …

struct AnimeRelatedEntityDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let type: String?
    let name: String?
    let url: String?

    var id: Int { malId }
}

// MARK: - Characters

struct AnimeCharactersResponse: Codable {
    let data: [AnimeCharacterRoleDTO]
}

struct AnimeCharacterRoleDTO: Codable, Identifiable, Hashable {
    let role: String?
    let favorites: Int?
    let character: AnimeCharacterEntryDTO?
    let voiceActors: [AnimeCharacterVoiceActorDTO]?

    var id: Int { character?.malId ?? role.hashValue }
}

struct AnimeCharacterEntryDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nameKanji: String?

    var id: Int { malId }
}

struct AnimeCharacterVoiceActorDTO: Codable, Identifiable, Hashable {
    let language: String?
    let person: AnimeCharacterVoicePersonDTO?

    var id: Int { person?.malId ?? language.hashValue }
}

struct AnimeCharacterVoicePersonDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nameKanji: String?

    var id: Int { malId }
}

// MARK: - Recommendations

struct AnimeRecommendationsResponse: Codable {
    let data: [AnimeRecommendationDTO]
}

struct AnimeRecommendationDTO: Codable, Identifiable, Hashable {
    let entry: AnimeRecommendationEntryDTO?
    let content: String?
    let votes: Int?

    var id: Int { entry?.malId ?? content.hashValue }
}

struct AnimeRecommendationEntryDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?

    var id: Int { malId }
}

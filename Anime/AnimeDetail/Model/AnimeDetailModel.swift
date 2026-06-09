//
//  AnimeDetailModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

// MARK: - Response (Jikan /anime/{id})

nonisolated struct AnimeDetailResponse: Codable, Sendable {
    let data: AnimeDetailDTO
}

// MARK: - Anime detail

nonisolated struct AnimeDetailDTO: Codable, Identifiable, Hashable, Sendable {
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

nonisolated struct AnimeDetailTrailerDTO: Codable, Hashable, Sendable {
    let youtubeId: String?
    let url: String?
    let embedUrl: String?
    let images: AnimeTrailerImagesDTO?
}

nonisolated struct AnimeTrailerImagesDTO: Codable, Hashable, Sendable {
    let imageUrl: String?
    let smallImageUrl: String?
    let mediumImageUrl: String?
    let largeImageUrl: String?
    let maximumImageUrl: String?
}

// MARK: - Titles

nonisolated struct AnimeTitleEntryDTO: Codable, Hashable, Sendable {
    let type: String?
    let title: String?
}

// MARK: - Aired

nonisolated struct AnimeAiredDTO: Codable, Hashable, Sendable {
    let from: String?
    let to: String?
    let prop: AnimeAiredPropDTO?
    let string: String?
}

nonisolated struct AnimeAiredPropDTO: Codable, Hashable, Sendable {
    let from: AnimeDatePartsDTO?
    let to: AnimeDatePartsDTO?
}

nonisolated struct AnimeDatePartsDTO: Codable, Hashable, Sendable {
    let day: Int?
    let month: Int?
    let year: Int?
}

// MARK: - Broadcast

nonisolated struct AnimeBroadcastDTO: Codable, Hashable, Sendable {
    let day: String?
    let time: String?
    let timezone: String?
    let string: String?
}

// MARK: - Producer / studio / genre …

nonisolated struct AnimeRelatedEntityDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let type: String?
    let name: String?
    let url: String?

    var id: Int { malId }
}

// MARK: - Characters

nonisolated struct AnimeCharactersResponse: Codable, Sendable {
    let data: [AnimeCharacterRoleDTO]
}

nonisolated struct AnimeCharacterRoleDTO: Codable, Identifiable, Hashable, Sendable {
    let role: String?
    let favorites: Int?
    let character: AnimeCharacterEntryDTO?
    let voiceActors: [AnimeCharacterVoiceActorDTO]?

    var id: Int { character?.malId ?? role.hashValue }
}

nonisolated struct AnimeCharacterEntryDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nameKanji: String?

    var id: Int { malId }
}

nonisolated struct AnimeCharacterVoiceActorDTO: Codable, Identifiable, Hashable, Sendable {
    let language: String?
    let person: AnimeCharacterVoicePersonDTO?

    var id: Int { person?.malId ?? language.hashValue }
}

nonisolated struct AnimeCharacterVoicePersonDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nameKanji: String?

    var id: Int { malId }
}

// MARK: - Recommendations

nonisolated struct AnimeRecommendationsResponse: Codable, Sendable {
    let data: [AnimeRecommendationDTO]
}

nonisolated struct AnimeRecommendationDTO: Codable, Identifiable, Hashable, Sendable {
    let entry: AnimeRecommendationEntryDTO?
    let content: String?
    let votes: Int?

    var id: Int { entry?.malId ?? content.hashValue }
}

nonisolated struct AnimeRecommendationEntryDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?

    var id: Int { malId }
}

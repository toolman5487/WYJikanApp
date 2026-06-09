//
//  CharacterDetailModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import Foundation

nonisolated struct CharacterDetailResponse: Codable, Sendable {
    let data: CharacterDetailDTO
}

nonisolated struct CharacterDetailDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nameKanji: String?
    let nicknames: [String]?
    let favorites: Int?
    let about: String?
    let anime: [CharacterAnimeRoleDTO]?
    let manga: [CharacterMangaRoleDTO]?
    let voices: [CharacterVoiceActorDTO]?

    var id: Int { malId }
}

nonisolated struct CharacterAnimeRoleDTO: Codable, Identifiable, Hashable, Sendable {
    let role: String?
    let anime: CharacterRelatedWorkDTO?

    var id: Int { anime?.malId ?? role.hashValue }
}

nonisolated struct CharacterMangaRoleDTO: Codable, Identifiable, Hashable, Sendable {
    let role: String?
    let manga: CharacterRelatedWorkDTO?

    var id: Int { manga?.malId ?? role.hashValue }
}

nonisolated struct CharacterRelatedWorkDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?

    var id: Int { malId }
}

nonisolated struct CharacterVoiceActorDTO: Codable, Identifiable, Hashable, Sendable {
    let language: String?
    let person: CharacterPersonDTO?

    var id: Int { person?.malId ?? language.hashValue }
}

nonisolated struct CharacterPersonDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?

    var id: Int { malId }
}

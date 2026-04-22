//
//  CharacterDetailModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import Foundation

struct CharacterDetailResponse: Codable {
    let data: CharacterDetailDTO
}

struct CharacterDetailDTO: Codable, Identifiable, Hashable {
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

struct CharacterAnimeRoleDTO: Codable, Identifiable, Hashable {
    let role: String?
    let anime: CharacterRelatedWorkDTO?

    var id: Int { anime?.malId ?? role.hashValue }
}

struct CharacterMangaRoleDTO: Codable, Identifiable, Hashable {
    let role: String?
    let manga: CharacterRelatedWorkDTO?

    var id: Int { manga?.malId ?? role.hashValue }
}

struct CharacterRelatedWorkDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?

    var id: Int { malId }
}

struct CharacterVoiceActorDTO: Codable, Identifiable, Hashable {
    let language: String?
    let person: CharacterPersonDTO?

    var id: Int { person?.malId ?? language.hashValue }
}

struct CharacterPersonDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?

    var id: Int { malId }
}

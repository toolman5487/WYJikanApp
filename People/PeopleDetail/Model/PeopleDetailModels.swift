//
//  PeopleDetailModels.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import Foundation

nonisolated struct PeopleDetailResponse: Codable, Sendable {
    let data: PeopleDetailDTO
}

nonisolated struct PeopleDetailDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let websiteUrl: String?
    let images: AnimeImagesDTO?
    let name: String?
    let givenName: String?
    let familyName: String?
    let alternateNames: [String]?
    let birthday: String?
    let favorites: Int?
    let about: String?
    let anime: [PeopleAnimeStaffPositionDTO]?
    let manga: [PeopleMangaStaffPositionDTO]?
    let voices: [PeopleVoiceRoleDTO]?

    var id: Int { malId }
}

nonisolated struct PeopleAnimeStaffPositionDTO: Codable, Identifiable, Hashable, Sendable {
    let position: String?
    let anime: PeopleRelatedWorkDTO?

    var id: Int { anime?.malId ?? position.hashValue }
}

nonisolated struct PeopleMangaStaffPositionDTO: Codable, Identifiable, Hashable, Sendable {
    let position: String?
    let manga: PeopleRelatedWorkDTO?

    var id: Int { manga?.malId ?? position.hashValue }
}

nonisolated struct PeopleVoiceRoleDTO: Codable, Identifiable, Hashable, Sendable {
    let role: String?
    let anime: PeopleRelatedWorkDTO?
    let character: PeopleRelatedCharacterDTO?

    var id: Int {
        let animeId = anime?.malId ?? 0
        let characterId = character?.malId ?? 0
        return animeId.hashValue ^ characterId.hashValue ^ (role?.hashValue ?? 0)
    }
}

nonisolated struct PeopleRelatedWorkDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?

    var id: Int { malId }
}

nonisolated struct PeopleRelatedCharacterDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?

    var id: Int { malId }
}

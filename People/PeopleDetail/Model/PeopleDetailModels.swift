//
//  PeopleDetailModels.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import Foundation

struct PeopleDetailResponse: Codable {
    let data: PeopleDetailDTO
}

struct PeopleDetailDTO: Codable, Identifiable, Hashable {
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

struct PeopleAnimeStaffPositionDTO: Codable, Identifiable, Hashable {
    let position: String?
    let anime: PeopleRelatedWorkDTO?

    var id: Int { anime?.malId ?? position.hashValue }
}

struct PeopleMangaStaffPositionDTO: Codable, Identifiable, Hashable {
    let position: String?
    let manga: PeopleRelatedWorkDTO?

    var id: Int { manga?.malId ?? position.hashValue }
}

struct PeopleVoiceRoleDTO: Codable, Identifiable, Hashable {
    let role: String?
    let anime: PeopleRelatedWorkDTO?
    let character: PeopleRelatedCharacterDTO?

    var id: Int {
        let animeId = anime?.malId ?? 0
        let characterId = character?.malId ?? 0
        return animeId.hashValue ^ characterId.hashValue ^ (role?.hashValue ?? 0)
    }
}

struct PeopleRelatedWorkDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?

    var id: Int { malId }
}

struct PeopleRelatedCharacterDTO: Codable, Identifiable, Hashable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?

    var id: Int { malId }
}

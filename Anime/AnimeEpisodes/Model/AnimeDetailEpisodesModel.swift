//
//  AnimeDetailEpisodesModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation

struct AnimeEpisodesResponse: Codable {
    let pagination: AnimeEpisodesPaginationDTO?
    let data: [AnimeEpisodeDTO]
}

struct AnimeEpisodesPaginationDTO: Codable, Hashable, Sendable {
    let lastVisiblePage: Int?
    let hasNextPage: Bool?
}

struct AnimeEpisodeDTO: Codable, Identifiable, Hashable {
    let malId: Int?
    let url: String?
    let title: String?
    let titleJapanese: String?
    let titleRomanji: String?
    let aired: String?
    let filler: Bool?
    let recap: Bool?
    let synopsis: String?
    let forumUrl: String?

    var id: Int {
        malId ?? ((title?.hashValue ?? 0) ^ (aired?.hashValue ?? 0))
    }
}

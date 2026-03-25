//
//  HeroBannerModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Foundation

// MARK: - Response

struct HeroBannerResponse: Codable {
    let pagination: Pagination
    let data: [HeroBannerAnimeDTO]
}

// MARK: - Pagination

struct Pagination: Codable {
    let lastVisiblePage: Int?
    let hasNextPage: Bool
    let currentPage: Int?
    let items: PaginationItems?

    enum CodingKeys: String, CodingKey {
        case lastVisiblePage = "last_visible_page"
        case hasNextPage = "has_next_page"
        case currentPage = "current_page"
        case items
    }
}

struct PaginationItems: Codable {
    let count: Int?
    let total: Int?
    let perPage: Int?

    enum CodingKeys: String, CodingKey {
        case count
        case total
        case perPage = "per_page"
    }
}

// MARK: - Anime DTO

struct HeroBannerAnimeDTO: Codable, Identifiable, Hashable {
    let malID: Int
    let url: String?
    let images: AnimeImagesDTO?
    let trailer: AnimeTrailerDTO?
    let approved: Bool?
    let titles: [AnimeTitleDTO]?
    let title: String
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
    let producers: [AnimeMetaDTO]?
    let licensors: [AnimeMetaDTO]?
    let studios: [AnimeMetaDTO]?
    let genres: [AnimeMetaDTO]?
    let explicitGenres: [AnimeMetaDTO]?
    let themes: [AnimeMetaDTO]?
    let demographics: [AnimeMetaDTO]?

    enum CodingKeys: String, CodingKey {
        case malID = "mal_id"
        case url
        case images
        case trailer
        case approved
        case titles
        case title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case titleSynonyms = "title_synonyms"
        case type
        case source
        case episodes
        case status
        case airing
        case aired
        case duration
        case rating
        case score
        case scoredBy = "scored_by"
        case rank
        case popularity
        case members
        case favorites
        case synopsis
        case background
        case season
        case year
        case broadcast
        case producers
        case licensors
        case studios
        case genres
        case explicitGenres = "explicit_genres"
        case themes
        case demographics
    }

    var id: Int { malID }
}

// MARK: - Images

struct AnimeImagesDTO: Codable, Hashable {
    let jpg: AnimeImageVariantDTO?
    let webp: AnimeImageVariantDTO?
}

struct AnimeImageVariantDTO: Codable, Hashable {
    let imageURL: String?
    let smallImageURL: String?
    let largeImageURL: String?

    enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
        case smallImageURL = "small_image_url"
        case largeImageURL = "large_image_url"
    }
}

// MARK: - Trailer

struct AnimeTrailerDTO: Codable, Hashable {
    let youtubeID: String?
    let url: String?
    let embedURL: String?
    let images: AnimeTrailerImagesDTO?

    enum CodingKeys: String, CodingKey {
        case youtubeID = "youtube_id"
        case url
        case embedURL = "embed_url"
        case images
    }
}

struct AnimeTrailerImagesDTO: Codable, Hashable {
    let imageURL: String?
    let smallImageURL: String?
    let mediumImageURL: String?
    let largeImageURL: String?
    let maximumImageURL: String?

    enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
        case smallImageURL = "small_image_url"
        case mediumImageURL = "medium_image_url"
        case largeImageURL = "large_image_url"
        case maximumImageURL = "maximum_image_url"
    }
}

// MARK: - Titles

struct AnimeTitleDTO: Codable, Hashable {
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

// MARK: - Meta

struct AnimeMetaDTO: Codable, Hashable {
    let malID: Int
    let type: String?
    let name: String
    let url: String?

    enum CodingKeys: String, CodingKey {
        case malID = "mal_id"
        case type
        case name
        case url
    }
}

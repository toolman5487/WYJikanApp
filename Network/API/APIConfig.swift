//
//  APIConfig.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/24.
//

import Foundation

// MARK: - APIConfig

nonisolated enum APIConfig {

    static let jikanBaseURL = "https://api.jikan.moe/v4"

    // MARK: - Anime

    enum Anime {
        static let list = "/anime"
        static func detail(id: Int) -> String { "/anime/\(id)" }
        static func characters(id: Int) -> String { "/anime/\(id)/characters" }
        static func episodes(id: Int) -> String { "/anime/\(id)/episodes" }
        static func episodeDetail(id: Int, episode: Int) -> String { "/anime/\(id)/episodes/\(episode)" }
        static func recommendations(id: Int) -> String { "/anime/\(id)/recommendations" }
        static func reviews(id: Int) -> String { "/anime/\(id)/reviews" }
        static func pictures(id: Int) -> String { "/anime/\(id)/pictures" }
    }

    // MARK: - Manga

    enum Manga {
        static let list = "/manga"
        static func detail(id: Int) -> String { "/manga/\(id)" }
        static func characters(id: Int) -> String { "/manga/\(id)/characters" }
        static func recommendations(id: Int) -> String { "/manga/\(id)/recommendations" }
        static func reviews(id: Int) -> String { "/manga/\(id)/reviews" }
        static func pictures(id: Int) -> String { "/manga/\(id)/pictures" }
    }

    // MARK: - Characters

    enum Characters {
        static let list = "/characters"
        static func detail(id: Int) -> String { "/characters/\(id)" }
        static func full(id: Int) -> String { "/characters/\(id)/full" }
    }

    // MARK: - People

    enum People {
        static let list = "/people"
        static func detail(id: Int) -> String { "/people/\(id)" }
        static func full(id: Int) -> String { "/people/\(id)/full" }
    }

    // MARK: - Top

    enum Top {
        static let anime = "/top/anime"
        static let manga = "/top/manga"
        static let characters = "/top/characters"
        static let people = "/top/people"
    }

    // MARK: - Seasons

    enum Seasons {
        static func now() -> String { "/seasons/now" }
        static func list(year: Int, season: String) -> String { "/seasons/\(year)/\(season)" }
    }

    // MARK: - Schedules

    enum Schedules {
        static let list = "/schedules"
        static func day(_ day: String) -> String { "/schedules/\(day)" }
    }

    // MARK: - Random

    enum Random {
        static let anime = "/random/anime"
        static let manga = "/random/manga"
    }

    // MARK: - Recommendations

    enum Recommendations {
        static let anime = "/recommendations/anime"
        static let manga = "/recommendations/manga"
    }

    // MARK: - Watch

    enum Watch {
        static let episodes = "/watch/episodes"
        static let popularEpisodes = "/watch/episodes/popular"
        static let promos = "/watch/promos"
        static let popularPromos = "/watch/promos/popular"
    }

    // MARK: - Users

    enum Users {
        static func profile(username: String) -> String { "/users/\(username)/full" }
        static func animeList(username: String) -> String { "/users/\(username)/animelist" }
        static func mangaList(username: String) -> String { "/users/\(username)/mangalist" }
    }

    // MARK: - Genres

    enum Genres {
        static let anime = "/genres/anime"
        static let manga = "/genres/manga"
    }

    // MARK: - Producers

    enum Producers {
        static let list = "/producers"
        static func detail(id: Int) -> String { "/producers/\(id)" }
        static func full(id: Int) -> String { "/producers/\(id)/full" }
    }

    // MARK: - Magazines

    enum Magazines {
        static let list = "/magazines"
    }
}

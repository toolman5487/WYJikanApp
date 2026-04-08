//
//  MainCategoryListService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation

protocol MainCategoryListServicing {
    func fetchRandomAnime() async throws -> AnimeListRandomResponse
}

final class MainCategoryListService: MainCategoryListServicing {
    private let apiService: JikanAPIService

    init(apiService: JikanAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchRandomAnime() async throws -> AnimeListRandomResponse {
        try await apiService.fetch(endpoint: APIConfig.Random.anime)
    }
}

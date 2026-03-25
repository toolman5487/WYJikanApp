//
//  MainHomeService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Foundation

protocol MainHomeServicing {
    func fetchHeroBanner() async throws -> HeroBannerResponse
}

final class MainHomeService: MainHomeServicing {

    private let apiService: JikanAPIService

    init(apiService: JikanAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchHeroBanner() async throws -> HeroBannerResponse {
        try await apiService.fetch(endpoint: APIConfig.Seasons.now())
    }
}


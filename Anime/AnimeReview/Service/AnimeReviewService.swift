//
//  AnimeReviewService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation

protocol AnimeReviewServicing {
    func fetchReviews(malId: Int, page: Int) async throws -> AnimeReviewsListResponse
}

final class AnimeReviewService: AnimeReviewServicing {

    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchReviews(malId: Int, page: Int) async throws -> AnimeReviewsListResponse {
        let query = [URLQueryItem(name: "page", value: String(page))]
        return try await apiService.fetch(endpoint: APIConfig.Anime.reviews(id: malId), queryItems: query)
    }
}

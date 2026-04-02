//
//  MangaReviewService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Foundation

protocol MangaReviewServicing {
    func fetchReviews(malId: Int, page: Int) async throws -> MangaReviewsListResponse
}

final class MangaReviewService: MangaReviewServicing {

    private let apiService: JikanAPIService

    init(apiService: JikanAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchReviews(malId: Int, page: Int) async throws -> MangaReviewsListResponse {
        let query = [URLQueryItem(name: "page", value: String(page))]
        return try await apiService.fetch(endpoint: APIConfig.Manga.reviews(id: malId), queryItems: query)
    }
}

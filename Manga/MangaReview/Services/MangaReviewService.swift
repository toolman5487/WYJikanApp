//
//  MangaReviewService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Foundation

nonisolated protocol MangaReviewServicing: Sendable {
    func fetchReviews(malId: Int, page: Int) async throws -> MangaReviewsListResponse
}

nonisolated final class MangaReviewService: MangaReviewServicing {

    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchReviews(malId: Int, page: Int) async throws -> MangaReviewsListResponse {
        let query = [URLQueryItem(name: "page", value: String(page))]
        return try await apiService.fetch(endpoint: APIConfig.Manga.reviews(id: malId), queryItems: query)
    }
}

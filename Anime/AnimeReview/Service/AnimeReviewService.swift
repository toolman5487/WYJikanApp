//
//  AnimeReviewService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation

nonisolated protocol AnimeReviewServicing: Sendable {
    func fetchReviews(malId: Int, page: Int) async throws -> AnimeReviewsListResponse
}

nonisolated final class AnimeReviewService: AnimeReviewServicing {

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    init(
        apiService: JikanAPIServicing = JikanAPIService.shared,
        lifecycleScope: RequestLifecycleScope = .independent
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    func fetchReviews(malId: Int, page: Int) async throws -> AnimeReviewsListResponse {
        let query = [URLQueryItem(name: "page", value: String(page))]
        return try await apiService.fetch(
            endpoint: APIConfig.Anime.reviews(id: malId),
            cachePolicy: .remoteOnly,
            queryItems: query,
            lifecycleScope: lifecycleScope
        )
    }
}

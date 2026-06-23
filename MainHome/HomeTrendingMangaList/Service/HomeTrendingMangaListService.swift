//
//  HomeTrendingMangaListService.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/6.
//

import Foundation

// MARK: - HomeTrendingMangaListServicing

nonisolated protocol HomeTrendingMangaListServicing: Sendable {
    func fetchPage(page: Int, limit: Int) async throws -> MangaCategoryPage
}

// MARK: - HomeTrendingMangaListService

nonisolated final class HomeTrendingMangaListService: HomeTrendingMangaListServicing {

    // MARK: - Properties

    private let apiService: JikanAPIServicing

    // MARK: - Lifecycle

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    // MARK: - Public Methods

    func fetchPage(page: Int, limit: Int) async throws -> MangaCategoryPage {
        let response: MangaCategoryResponse = try await apiService.fetch(
            endpoint: APIConfig.Top.manga,
            cachePolicy: .paging(page: page),
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ],
            lifecycleScope: .homeTrendingMangaList
        )

        return MangaCategoryPage(
            items: response.data,
            currentPage: response.pagination?.currentPage ?? page,
            hasNextPage: response.pagination?.hasNextPage ?? !response.data.isEmpty
        )
    }
}

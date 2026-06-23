//
//  ProducerDetailService.swift
//  WYJikanApp
//

import Foundation

// MARK: - ProducerDetailServicing

nonisolated protocol ProducerDetailServicing: Sendable {
    func fetchProducerDetail(malId: Int) async throws -> ProducerDetailResponse
    func fetchRelatedAnimePreview(
        producerId: Int,
        limit: Int
    ) async throws -> AnimeCategoryPage
}

// MARK: - ProducerDetailService

nonisolated final class ProducerDetailService: ProducerDetailServicing {

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    init(
        apiService: JikanAPIServicing = JikanAPIService.shared,
        lifecycleScope: RequestLifecycleScope = .independent
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    func fetchProducerDetail(malId: Int) async throws -> ProducerDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Producers.full(id: malId),
            cachePolicy: .cacheFirst(ttl: 600),
            lifecycleScope: lifecycleScope
        )
    }

    func fetchRelatedAnimePreview(
        producerId: Int,
        limit: Int
    ) async throws -> AnimeCategoryPage {
        let response: AnimeCategoryResponse = try await apiService.fetch(
            endpoint: APIConfig.Anime.list,
            cachePolicy: .cacheFirst(ttl: 600),
            queryItems: [
                URLQueryItem(name: "producers", value: String(producerId)),
                URLQueryItem(name: "order_by", value: "score"),
                URLQueryItem(name: "sort", value: "desc"),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: String(limit))
            ],
            lifecycleScope: lifecycleScope
        )

        return AnimeCategoryPage(
            items: response.data,
            currentPage: response.pagination?.currentPage ?? 1,
            hasNextPage: response.pagination?.hasNextPage ?? false
        )
    }
}

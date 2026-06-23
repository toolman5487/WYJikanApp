//
//  ProducerAnimeListService.swift
//  WYJikanApp
//

import Foundation

// MARK: - ProducerAnimeListServicing

nonisolated protocol ProducerAnimeListServicing: Sendable {
    func fetchAnimePage(
        producerId: Int,
        page: Int,
        pageSize: Int,
        filter: AnimeCategoryFilter
    ) async throws -> AnimeCategoryPage
}

// MARK: - ProducerAnimeListService

nonisolated final class ProducerAnimeListService: ProducerAnimeListServicing {

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    init(
        apiService: JikanAPIServicing = JikanAPIService.shared,
        lifecycleScope: RequestLifecycleScope = .independent
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    func fetchAnimePage(
        producerId: Int,
        page: Int,
        pageSize: Int,
        filter: AnimeCategoryFilter
    ) async throws -> AnimeCategoryPage {
        var queryItems = [
            URLQueryItem(name: "producers", value: String(producerId)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(pageSize))
        ]
        queryItems.append(contentsOf: filterQueryItems(for: filter))

        let response: AnimeCategoryResponse = try await apiService.fetch(
            endpoint: APIConfig.Anime.list,
            cachePolicy: .paging(page: page),
            queryItems: queryItems,
            lifecycleScope: lifecycleScope
        )

        return AnimeCategoryPage(
            items: response.data,
            currentPage: response.pagination?.currentPage ?? page,
            hasNextPage: response.pagination?.hasNextPage ?? !response.data.isEmpty
        )
    }

    // MARK: - Private Methods

    private func filterQueryItems(
        for filter: AnimeCategoryFilter
    ) -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        if let type = filter.format.apiValue {
            items.append(URLQueryItem(name: "type", value: type))
        }

        switch filter.sort {
        case .defaultSort:
            break
        case .popularity:
            items.append(URLQueryItem(name: "order_by", value: "popularity"))
            items.append(URLQueryItem(name: "sort", value: "asc"))
        case .score:
            items.append(URLQueryItem(name: "order_by", value: "score"))
            items.append(URLQueryItem(name: "sort", value: "desc"))
        case .rank:
            items.append(URLQueryItem(name: "order_by", value: "rank"))
            items.append(URLQueryItem(name: "sort", value: "asc"))
        case .newest:
            items.append(URLQueryItem(name: "order_by", value: "start_date"))
            items.append(URLQueryItem(name: "sort", value: "desc"))
        case .oldest:
            items.append(URLQueryItem(name: "order_by", value: "start_date"))
            items.append(URLQueryItem(name: "sort", value: "asc"))
        }

        return items
    }
}

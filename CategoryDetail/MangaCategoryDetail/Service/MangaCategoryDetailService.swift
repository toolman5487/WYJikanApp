//
//  MangaCategoryDetailService.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import Foundation

nonisolated protocol MangaCategoryDetailServicing: Sendable {
    func fetchInitialPage(
        genreId: Int,
        pageSize: Int,
        filter: MangaCategoryFilter
    ) async throws -> MangaCategoryPage

    func fetchPage(
        genreId: Int,
        page: Int,
        pageSize: Int,
        filter: MangaCategoryFilter
    ) async throws -> MangaCategoryPage
}

nonisolated final class MangaCategoryDetailService: MangaCategoryDetailServicing {
    // MARK: - Request

    private enum MangaGenreRequest {
        case page(genreId: Int, page: Int, pageSize: Int, filter: MangaCategoryFilter)

        var endpoint: String {
            APIConfig.Manga.list
        }

        var queryItems: [URLQueryItem] {
            switch self {
            case let .page(genreId, page, pageSize, filter):
                return baseQueryItems(genreId: genreId, page: page, pageSize: pageSize)
                    + filterQueryItems(for: filter)
            }
        }

        var cachePolicy: JikanAPICachePolicy {
            switch self {
            case .page(_, let page, _, _):
                return .paging(page: page)
            }
        }

        private func baseQueryItems(genreId: Int, page: Int, pageSize: Int) -> [URLQueryItem] {
            [
                URLQueryItem(name: "genres", value: "\(genreId)"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(pageSize)")
            ]
        }

        private func filterQueryItems(for filter: MangaCategoryFilter) -> [URLQueryItem] {
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

    // MARK: - Dependencies

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    init(
        apiService: JikanAPIServicing,
        lifecycleScope: RequestLifecycleScope
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    // MARK: - Public API

    func fetchInitialPage(
        genreId: Int,
        pageSize: Int,
        filter: MangaCategoryFilter
    ) async throws -> MangaCategoryPage {
        try await fetchPage(
            genreId: genreId,
            page: 1,
            pageSize: pageSize,
            filter: filter
        )
    }

    func fetchPage(
        genreId: Int,
        page: Int,
        pageSize: Int,
        filter: MangaCategoryFilter
    ) async throws -> MangaCategoryPage {
        let request = MangaGenreRequest.page(
            genreId: genreId,
            page: page,
            pageSize: pageSize,
            filter: filter
        )
        let response: MangaCategoryResponse = try await apiService.fetch(
            endpoint: request.endpoint,
            cachePolicy: request.cachePolicy,
            queryItems: request.queryItems,
            lifecycleScope: lifecycleScope
        )
        return MangaCategoryPage(
            items: response.data,
            currentPage: response.pagination?.currentPage ?? page,
            hasNextPage: response.pagination?.hasNextPage ?? !response.data.isEmpty
        )
    }
}

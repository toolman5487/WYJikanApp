//
//  MangaCategoryDetailService.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import Foundation

protocol MangaCategoryDetailServicing {
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

final class MangaCategoryDetailService: MangaCategoryDetailServicing {
    // MARK: - Request

    private enum MangaGenreRequest {
        case page(genreId: Int, page: Int, pageSize: Int, filter: MangaCategoryFilter)

        var request: JikanAPIRequest {
            switch self {
            case let .page(genreId, page, pageSize, filter):
                return JikanAPIRequest(
                    path: APIConfig.Manga.list,
                    queryItems: baseQueryItems(genreId: genreId, page: page, pageSize: pageSize)
                        + filterQueryItems(for: filter),
                    cachePolicy: cachePolicy
                )
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
            case .default:
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

        private var cachePolicy: JikanAPICachePolicy {
            switch self {
            case .page(_, let page, _, _):
                switch page {
                case 1:
                    return .cacheFirst(ttl: 300)
                default:
                    return .cacheFirst(ttl: 120)
                }
            }
        }
    }

    // MARK: - Dependencies

    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
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
        let response: MangaCategoryResponse = try await apiService.send(request.request)
        return MangaCategoryPage(
            items: response.data,
            currentPage: response.pagination?.currentPage ?? page,
            hasNextPage: response.pagination?.hasNextPage ?? !response.data.isEmpty
        )
    }
}

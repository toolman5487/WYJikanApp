//
//  AnimeCategoryDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/2.
//

import Foundation

protocol AnimeCategoryDetailServicing {
    func fetchInitialPage(
        genreId: Int,
        pageSize: Int,
        filter: AnimeCategoryFilter
    ) async throws -> AnimeCategoryPage

    func fetchPage(
        genreId: Int,
        page: Int,
        pageSize: Int,
        filter: AnimeCategoryFilter
    ) async throws -> AnimeCategoryPage
}

final class AnimeCategoryDetailService: AnimeCategoryDetailServicing {
    // MARK: - Request

    private enum AnimeGenreRequest {
        case page(genreId: Int, page: Int, pageSize: Int, filter: AnimeCategoryFilter)

        var request: JikanAPIRequest {
            switch self {
            case let .page(genreId, page, pageSize, filter):
                return JikanAPIRequest(
                    path: APIConfig.Anime.list,
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

        private func filterQueryItems(for filter: AnimeCategoryFilter) -> [URLQueryItem] {
            var items: [URLQueryItem] = []

            switch filter.format {
            case .all:
                break
            case .tv:
                items.append(URLQueryItem(name: "type", value: "tv"))
            case .movie:
                items.append(URLQueryItem(name: "type", value: "movie"))
            case .ova:
                items.append(URLQueryItem(name: "type", value: "ova"))
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
        filter: AnimeCategoryFilter
    ) async throws -> AnimeCategoryPage {
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
        filter: AnimeCategoryFilter
    ) async throws -> AnimeCategoryPage {
        let request = AnimeGenreRequest.page(
            genreId: genreId,
            page: page,
            pageSize: pageSize,
            filter: filter
        )
        let response: AnimeCategoryResponse = try await apiService.send(request.request)
        return AnimeCategoryPage(
            items: response.data,
            currentPage: response.pagination?.currentPage ?? page,
            hasNextPage: response.pagination?.hasNextPage ?? !response.data.isEmpty
        )
    }
}

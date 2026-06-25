//
//  HomeWatchService.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Foundation

// MARK: - HomeWatchServiceError

nonisolated enum HomeWatchServiceError: LocalizedError, AppUserFacingError {
    case invalidPagination(page: Int, limit: Int)

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidPagination(let page, let limit):
            return "Invalid HomeWatch pagination values: page \(page), limit \(limit)."
        }
    }

    nonisolated var userMessage: String {
        switch self {
        case .invalidPagination:
            return "影音列表參數暫時異常，請稍後再試。"
        }
    }
}

// MARK: - HomeWatchServicing

nonisolated protocol HomeWatchServicing: Sendable {
    func fetchLatestPromos(forceRefresh: Bool) async throws -> HomeWatchPromosResponse
    func fetchLatestEpisodes(forceRefresh: Bool) async throws -> HomeWatchEpisodesResponse
    func fetchPromos(
        feed: HomeWatchPromoFeed,
        page: Int,
        limit: Int,
        forceRefresh: Bool
    ) async throws -> HomeWatchPromosResponse
    func fetchEpisodes(
        feed: HomeWatchEpisodeFeed,
        page: Int,
        limit: Int,
        forceRefresh: Bool
    ) async throws -> HomeWatchEpisodesResponse
}

// MARK: - HomeWatchServicing Default Implementation

nonisolated extension HomeWatchServicing {
    func fetchLatestPromos() async throws -> HomeWatchPromosResponse {
        try await fetchLatestPromos(forceRefresh: false)
    }

    func fetchLatestEpisodes() async throws -> HomeWatchEpisodesResponse {
        try await fetchLatestEpisodes(forceRefresh: false)
    }
}

// MARK: - HomeWatchService

nonisolated final class HomeWatchService: HomeWatchServicing {

    // MARK: - Constants

    private enum Constants {
        static let firstPage = 1
        static let latestPromosLimit = 8
        static let latestEpisodesLimit = 10
        static let latestFeedCacheTTL: TimeInterval = 300
        static let popularFeedCacheTTL: TimeInterval = 600
    }

    // MARK: - Properties

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    // MARK: - Lifecycle

    init(
        apiService: JikanAPIServicing,
        lifecycleScope: RequestLifecycleScope
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    // MARK: - Public Methods

    func fetchLatestPromos(forceRefresh: Bool) async throws -> HomeWatchPromosResponse {
        try await fetchPromos(
            feed: .latest,
            page: Constants.firstPage,
            limit: Constants.latestPromosLimit,
            forceRefresh: forceRefresh
        )
    }

    func fetchLatestEpisodes(forceRefresh: Bool) async throws -> HomeWatchEpisodesResponse {
        try await fetchEpisodes(
            feed: .latest,
            page: Constants.firstPage,
            limit: Constants.latestEpisodesLimit,
            forceRefresh: forceRefresh
        )
    }

    func fetchPromos(
        feed: HomeWatchPromoFeed,
        page: Int,
        limit: Int,
        forceRefresh: Bool
    ) async throws -> HomeWatchPromosResponse {
        try validate(page: page, limit: limit)

        let response: HomeWatchPromosResponse = try await apiService.fetch(
            endpoint: endpoint(for: feed),
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: ttl(for: feed)),
            queryItems: queryItems(page: page, limit: limit),
            lifecycleScope: lifecycleScope
        )
        return response
    }

    func fetchEpisodes(
        feed: HomeWatchEpisodeFeed,
        page: Int,
        limit: Int,
        forceRefresh: Bool
    ) async throws -> HomeWatchEpisodesResponse {
        try validate(page: page, limit: limit)

        let response: HomeWatchEpisodesResponse = try await apiService.fetch(
            endpoint: endpoint(for: feed),
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: ttl(for: feed)),
            queryItems: queryItems(page: page, limit: limit),
            lifecycleScope: lifecycleScope
        )
        return response
    }

    // MARK: - Private Methods

    private func endpoint(for feed: HomeWatchPromoFeed) -> String {
        switch feed {
        case .latest:
            return APIConfig.Watch.promos
        case .popular:
            return APIConfig.Watch.popularPromos
        }
    }

    private func endpoint(for feed: HomeWatchEpisodeFeed) -> String {
        switch feed {
        case .latest:
            return APIConfig.Watch.episodes
        case .popular:
            return APIConfig.Watch.popularEpisodes
        }
    }

    private func ttl(for feed: HomeWatchPromoFeed) -> TimeInterval {
        switch feed {
        case .latest:
            return Constants.latestFeedCacheTTL
        case .popular:
            return Constants.popularFeedCacheTTL
        }
    }

    private func ttl(for feed: HomeWatchEpisodeFeed) -> TimeInterval {
        switch feed {
        case .latest:
            return Constants.latestFeedCacheTTL
        case .popular:
            return Constants.popularFeedCacheTTL
        }
    }

    private func validate(page: Int, limit: Int) throws {
        guard page > 0, limit > 0 else {
            throw HomeWatchServiceError.invalidPagination(page: page, limit: limit)
        }
    }

    private func queryItems(page: Int, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
    }

    private func cachePolicy(forceRefresh: Bool, ttl: TimeInterval) -> JikanAPICachePolicy {
        .resolved(forceRefresh: forceRefresh, ttl: ttl)
    }
}

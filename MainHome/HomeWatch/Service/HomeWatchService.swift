//
//  HomeWatchService.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Foundation

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

nonisolated extension HomeWatchServicing {
    func fetchLatestPromos() async throws -> HomeWatchPromosResponse {
        try await fetchLatestPromos(forceRefresh: false)
    }

    func fetchLatestEpisodes() async throws -> HomeWatchEpisodesResponse {
        try await fetchLatestEpisodes(forceRefresh: false)
    }
}

nonisolated final class HomeWatchService: HomeWatchServicing {
    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchLatestPromos(forceRefresh: Bool) async throws -> HomeWatchPromosResponse {
        try await fetchPromos(
            feed: .latest,
            page: 1,
            limit: 8,
            forceRefresh: forceRefresh
        )
    }

    func fetchLatestEpisodes(forceRefresh: Bool) async throws -> HomeWatchEpisodesResponse {
        try await fetchEpisodes(
            feed: .latest,
            page: 1,
            limit: 10,
            forceRefresh: forceRefresh
        )
    }

    func fetchPromos(
        feed: HomeWatchPromoFeed,
        page: Int,
        limit: Int,
        forceRefresh: Bool
    ) async throws -> HomeWatchPromosResponse {
        try await apiService.fetch(
            endpoint: endpoint(for: feed),
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: ttl(for: feed)),
            queryItems: queryItems(page: page, limit: limit)
        )
    }

    func fetchEpisodes(
        feed: HomeWatchEpisodeFeed,
        page: Int,
        limit: Int,
        forceRefresh: Bool
    ) async throws -> HomeWatchEpisodesResponse {
        try await apiService.fetch(
            endpoint: endpoint(for: feed),
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: ttl(for: feed)),
            queryItems: queryItems(page: page, limit: limit)
        )
    }

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
            return 300
        case .popular:
            return 600
        }
    }

    private func ttl(for feed: HomeWatchEpisodeFeed) -> TimeInterval {
        switch feed {
        case .latest:
            return 300
        case .popular:
            return 600
        }
    }

    private func queryItems(page: Int, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
    }

    private func cachePolicy(forceRefresh: Bool, ttl: TimeInterval) -> JikanAPICachePolicy {
        forceRefresh ? .remoteOnly : .cacheFirst(ttl: ttl)
    }
}

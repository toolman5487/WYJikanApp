//
//  HomeRecommendedAnimeTitleEnricher.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Foundation

// MARK: - HomeRecommendedAnimeTitleEnricher

struct HomeRecommendedAnimeTitleEnricher {

    // MARK: - Properties

    private let service: AnimeDetailServicing
    private let textFormatter = MainHomeMediaTextFormatter()

    // MARK: - Lifecycle

    init(service: AnimeDetailServicing) {
        self.service = service
    }

    // MARK: - Public Methods

    func enrichedTitles(for malIds: [Int]) async -> [Int: String] {
        var titles: [Int: String] = [:]

        for malId in malIds {
            guard !Task.isCancelled else { return titles }

            do {
                let response = try await service.fetchAnimeDetail(malId: malId)
                titles[malId] = textFormatter.preferredTitle(
                    japanese: response.data.titleJapanese,
                    english: response.data.titleEnglish,
                    fallback: response.data.title,
                    defaultTitle: "推薦作品"
                )
            } catch {
                continue
            }
        }

        return titles
    }
}

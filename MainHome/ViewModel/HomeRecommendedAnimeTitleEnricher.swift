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
                titles[malId] = Self.preferredTitle(
                    japanese: response.data.titleJapanese,
                    english: response.data.titleEnglish,
                    fallback: response.data.title
                )
            } catch {
                continue
            }
        }

        return titles
    }

    // MARK: - Private Methods

    private static func preferredTitle(japanese: String?, english: String?, fallback: String?) -> String {
        if let japanese = normalizedText(japanese) {
            return japanese
        }
        if let english = normalizedText(english) {
            return english
        }
        if let fallback = normalizedText(fallback) {
            return fallback
        }
        return "推薦作品"
    }

    private static func normalizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}

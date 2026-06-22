//
//  HomeRecommendedAnimePresentationBuilder.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Foundation

// MARK: - HomeRecommendedAnimePresentationBuilder

nonisolated struct HomeRecommendedAnimePresentationBuilder: Sendable {
    private let textFormatter = MainHomeMediaTextFormatter()

    // MARK: - Public Methods

    func cardItems(from recommendations: [HomeRecommendedAnimeDTO]) -> [HomeRecommendedAnimeCardItem] {
        let mappedItems: [HomeRecommendedAnimeCardItem] = recommendations.compactMap { recommendation in
            guard recommendation.entry.count >= 2 else { return nil }

            let source = recommendation.entry[0]
            let recommended = recommendation.entry[1]
            guard let imageURL = JikanImageURLResolver.url(
                from: recommended.images,
                tier: .card
            ) else { return nil }

            return HomeRecommendedAnimeCardItem(
                id: recommendation.id,
                sourceTitle: textFormatter.preferredTitle(
                    japanese: nil,
                    english: nil,
                    fallback: source.title,
                    defaultTitle: "原作"
                ),
                recommendedTitle: textFormatter.preferredTitle(
                    japanese: nil,
                    english: nil,
                    fallback: recommended.title,
                    defaultTitle: "推薦作品"
                ),
                username: textFormatter.normalizedText(recommendation.user?.username),
                detailMalId: recommended.malId,
                imageURL: imageURL
            )
        }

        var seenRecommendationIDs = Set<String>()
        return mappedItems.filter { item in
            seenRecommendationIDs.insert(item.id).inserted
        }
    }
}

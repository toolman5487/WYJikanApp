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

    func cardItems(
        from recommendations: [HomeRecommendedAnimeDTO],
        titleCache: HomeRecommendedAnimeTitleCache
    ) -> [HomeRecommendedAnimeCardItem] {
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
                recommendedTitle: titleCache.title(for: recommended.malId) ??
                    textFormatter.preferredTitle(
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

// MARK: - HomeRecommendedAnimeTitleCache

nonisolated struct HomeRecommendedAnimeTitleCache: Sendable {
    private let titles: [Int: String]
    private let order: [Int]

    init(titles: [Int: String] = [:], order: [Int] = []) {
        self.titles = titles
        self.order = order
    }

    func title(for malId: Int) -> String? {
        titles[malId]
    }

    func storing(_ title: String, for malId: Int, limit: Int) -> Self {
        var updatedTitles = titles
        var updatedOrder = order
        updatedTitles[malId] = title
        updatedOrder.removeAll { $0 == malId }
        updatedOrder.append(malId)

        while updatedOrder.count > limit {
            let key = updatedOrder.removeFirst()
            updatedTitles.removeValue(forKey: key)
        }

        if updatedTitles.count > updatedOrder.count {
            for key in updatedTitles.keys where !updatedOrder.contains(key) {
                updatedTitles.removeValue(forKey: key)
            }
        }

        return Self(titles: updatedTitles, order: updatedOrder)
    }
}

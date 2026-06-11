//
//  AnimeDetailRecommendationsListLayout.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import SwiftUI

struct AnimeDetailRecommendationsListMetrics: Equatable {
    static let columnCount = 3
    static let horizontalPadding: CGFloat = 16
    static let columnSpacing: CGFloat = 12
    static let rowSpacing: CGFloat = 16
    static let titleSpacing: CGFloat = 8
    static let posterAspectHeightPerWidth: CGFloat = 1.5

    let cardWidth: CGFloat
    let posterHeight: CGFloat

    var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(cardWidth), spacing: Self.columnSpacing),
            count: Self.columnCount
        )
    }

    static func make(containerWidth: CGFloat) -> Self {
        let contentWidth = max(containerWidth - horizontalPadding * 2, 0)
        let totalColumnSpacing = columnSpacing * CGFloat(columnCount - 1)
        let cardWidth = floor((contentWidth - totalColumnSpacing) / CGFloat(columnCount))
        let posterHeight = floor(cardWidth * posterAspectHeightPerWidth)

        return Self(
            cardWidth: max(cardWidth, 0),
            posterHeight: max(posterHeight, 0)
        )
    }

    static let fallback = make(containerWidth: 390)
}

private struct AnimeDetailRecommendationsListMetricsKey: EnvironmentKey {
    static let defaultValue = AnimeDetailRecommendationsListMetrics.fallback
}

extension EnvironmentValues {
    var animeDetailRecommendationsListMetrics: AnimeDetailRecommendationsListMetrics {
        get { self[AnimeDetailRecommendationsListMetricsKey.self] }
        set { self[AnimeDetailRecommendationsListMetricsKey.self] = newValue }
    }
}

struct AnimeDetailRecommendationsListLayout<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let metrics = AnimeDetailRecommendationsListMetrics.make(
                containerWidth: geometry.size.width
            )

            ScrollView {
                LazyVGrid(
                    columns: metrics.gridColumns,
                    alignment: .leading,
                    spacing: AnimeDetailRecommendationsListMetrics.rowSpacing
                ) {
                    content()
                }
                .padding(.horizontal, AnimeDetailRecommendationsListMetrics.horizontalPadding)
                .padding(.vertical, AnimeDetailRecommendationsListMetrics.horizontalPadding)
            }
            .environment(\.animeDetailRecommendationsListMetrics, metrics)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

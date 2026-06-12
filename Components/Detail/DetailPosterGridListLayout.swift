//
//  DetailPosterGridListLayout.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/12.
//

import SwiftUI

struct DetailPosterGridListMetrics: Equatable {
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

private struct DetailPosterGridListMetricsKey: EnvironmentKey {
    static let defaultValue = DetailPosterGridListMetrics.fallback
}

extension EnvironmentValues {
    var detailPosterGridListMetrics: DetailPosterGridListMetrics {
        get { self[DetailPosterGridListMetricsKey.self] }
        set { self[DetailPosterGridListMetricsKey.self] = newValue }
    }
}

struct DetailPosterGridListLayout<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let metrics = DetailPosterGridListMetrics.make(
                containerWidth: geometry.size.width
            )

            ScrollView {
                LazyVGrid(
                    columns: metrics.gridColumns,
                    alignment: .leading,
                    spacing: DetailPosterGridListMetrics.rowSpacing
                ) {
                    content()
                }
                .padding(.horizontal, DetailPosterGridListMetrics.horizontalPadding)
                .padding(.vertical, DetailPosterGridListMetrics.horizontalPadding)
            }
            .environment(\.detailPosterGridListMetrics, metrics)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

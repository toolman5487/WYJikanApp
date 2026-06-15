import SwiftUI

struct MyListStatisticsSectionView: View {
    let presentation: MyListPresentation
    let onSelectGenre: (String) -> Void
    let onSelectFormat: (String) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private enum ContentState {
        case empty
        case populated
    }

    private var contentState: ContentState {
        presentation.filteredItems.isEmpty ? .empty : .populated
    }

    private var chartCardMinHeight: CGFloat? {
        horizontalSizeClass == .regular ? 320 : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MyListSummaryTile(
                title: presentation.summaryTile.title,
                value: presentation.summaryTile.value,
                iconName: presentation.summaryTile.iconName,
                detail: presentation.summaryTile.detail
            )

            switch contentState {
            case .empty:
                MyListStatisticsCardContainer(
                    title: "收藏總覽"
                ) {
                    FeatureEmptyStateInlineView(
                        emptyState: .emptyCollection(message: "尚無收藏統計"),
                        height: 120
                    )
                }

            case .populated:
                chartContent
            }
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 16) {
                formatChart
                genreChart
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                genreChart
                formatChart
            }
        }
    }

    private var genreChart: some View {
        MyListGenreDistributionChartCardView(
            statistics: presentation.statistics,
            cardMinHeight: chartCardMinHeight,
            onSelectGenre: onSelectGenre
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var formatChart: some View {
        MyListFormatDistributionChartCardView(
            statistics: presentation.statistics,
            cardMinHeight: chartCardMinHeight,
            onSelectFormat: onSelectFormat
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

}

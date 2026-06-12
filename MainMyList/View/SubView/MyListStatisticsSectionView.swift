import SwiftUI

struct MyListStatisticsSectionView: View {
    let presentation: MyListPresentation
    let onSelectGenre: (String) -> Void
    let onSelectFormat: (String) -> Void

    private enum ContentState {
        case empty
        case populated
    }

    private var contentState: ContentState {
        presentation.filteredItems.isEmpty ? .empty : .populated
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
                VStack(alignment: .leading, spacing: 16) {
                    MyListDistributionChartCardView(
                        statistics: presentation.statistics,
                        onSelectGenre: onSelectGenre
                    )
                    MyListFormatDistributionChartCardView(
                        statistics: presentation.statistics,
                        onSelectFormat: onSelectFormat
                    )
                }
            }
        }
    }

}

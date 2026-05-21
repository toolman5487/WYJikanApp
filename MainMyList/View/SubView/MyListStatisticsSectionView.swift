import SwiftUI

struct MyListStatisticsSectionView: View {
    let presentation: MainMyListViewModel.Presentation

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
                    emptyOverviewIllustration
                }

            case .populated:
                VStack(alignment: .leading, spacing: 16) {
                    MyListDistributionChartCardView(statistics: presentation.statistics)
                    MyListGenreInsightsCardView(statistics: presentation.statistics)
                }
            }
        }
    }

    private var emptyOverviewIllustration: some View {
        HStack {
            Spacer()

            Image(systemName: "tray.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            ThemeColor.textSecondary.opacity(0.52),
                            ThemeColor.textSecondary.opacity(0.24)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 120)
                .accessibilityLabel("尚無收藏統計")

            Spacer()
        }
    }
}

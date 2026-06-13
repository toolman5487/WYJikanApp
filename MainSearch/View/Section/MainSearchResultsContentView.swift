//
//  MainSearchResultsContentView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

struct MainSearchResultsContentView<FilterHeader: View>: View {

    let screenState: MainSearchScreenState
    let loadMoreState: MainSearchLoadMoreState
    let loadMoreProgress: CGFloat
    let searchHistory: [MainSearchHistoryItem]
    @ViewBuilder let filterHeader: () -> FilterHeader
    let onRowAppear: (MainSearchResultRow) -> Void
    let onLoadMore: () -> Void
    let onRetryLoadMore: () -> Void
    let onSelectHistory: (MainSearchHistoryItem) -> Void
    let onRemoveHistory: (MainSearchHistoryItem) -> Void
    let onClearHistory: () -> Void

    var body: some View {
        Group {
            switch screenState {
            case .emptyPrompt:
                VStack(spacing: 0) {
                    filterHeader()
                    if searchHistory.isEmpty {
                        FeatureEmptyStateCardView(
                            emptyState: .noSearchResults(
                                title: "開始搜尋",
                                message: "選擇類型，輸入上方搜尋列關鍵字。"
                            ),
                            minHeight: 200
                        )
                    } else {
                        MainSearchHistorySectionView(
                            items: searchHistory,
                            onSelect: onSelectHistory,
                            onRemove: onRemoveHistory,
                            onClear: onClearHistory
                        )
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }

                    Spacer(minLength: 0)
                }
            case .loading:
                VStack(spacing: 0) {
                    filterHeader()
                    MainSearchListSkeletonView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .error(let failure):
                VStack(spacing: 0) {
                    filterHeader()
                    ErrorMessageView(
                        state: ErrorMessageView.State(failure: failure),
                        height: 200
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .emptyResults(let query):
                VStack(spacing: 0) {
                    filterHeader()
                    FeatureEmptyStateCardView(
                        emptyState: .noSearchResults(
                            title: "找不到結果",
                            message: "沒有符合「\(query)」的結果，請換個關鍵字試試。"
                        ),
                        minHeight: 200
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .content(let rows):
                List {
                    Section {
                        ForEach(rows) { row in
                            NavigationLink(value: row) {
                                MainSearchResultRowView(row: row)
                            }
                            .onAppear {
                                onRowAppear(row)
                            }
                            .listRowSeparator(.visible)
                        }

                        loadMoreFooterView
                    } header: {
                        filterHeader()
                            .textCase(nil)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var loadMoreFooterView: some View {
        PaginationLoadMoreFooterView(
            state: loadMoreState,
            availablePresentation: .endBounceHint(
                title: "載入更多結果",
                subtitle: "繼續往下拉展開更多",
                progress: loadMoreProgress
            ),
            onAvailableTap: onLoadMore,
            onRetry: onRetryLoadMore
        )
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16))
    }
}

private struct MainSearchHistorySectionView: View {
    let items: [MainSearchHistoryItem]
    let onSelect: (MainSearchHistoryItem) -> Void
    let onRemove: (MainSearchHistoryItem) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Label("搜尋紀錄", systemImage: "clock.arrow.circlepath")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)

                Spacer()

                Button(role: .destructive, action: onClear) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("清除搜尋紀錄")
            }

            MainSearchHistoryFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(items) { item in
                    MainSearchHistoryChipView(
                        item: item,
                        onSelect: onSelect,
                        onRemove: onRemove
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MainSearchHistoryChipView: View {
    let item: MainSearchHistoryItem
    let onSelect: (MainSearchHistoryItem) -> Void
    let onRemove: (MainSearchHistoryItem) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button {
                onSelect(item)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: item.kind.historyIconSystemName)
                        .font(.footnote.weight(.semibold))

                    Text(item.query)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(ThemeColor.textPrimary)
            }
            .buttonStyle(.plain)

            Button {
                onRemove(item)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(width: 24, height: 24)
                    .foregroundStyle(ThemeColor.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("刪除 \(item.query)")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .frame(minHeight: 44)
        .background {
            Capsule()
                .fill(Color(.secondarySystemBackground).opacity(0.95))
        }
        .overlay {
            Capsule()
                .strokeBorder(ThemeColor.sakura.opacity(0.12), lineWidth: 1)
        }
        .clipShape(Capsule())
    }
}

private struct MainSearchHistoryFlowLayout: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0
        let rows = rows(in: maxWidth, subviews: subviews)
        return CGSize(
            width: maxWidth,
            height: rows.last.map { $0.y + $0.height } ?? 0
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        for row in rows(in: bounds.width, subviews: subviews) {
            var x = bounds.minX

            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: bounds.minY + row.y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: item.size.width, height: item.size.height)
                )
                x += item.size.width + horizontalSpacing
            }
        }
    }

    private func rows(in maxWidth: CGFloat, subviews: Subviews) -> [FlowRow] {
        guard !subviews.isEmpty else { return [] }

        let availableWidth = max(maxWidth, 0)
        var rows: [FlowRow] = []
        var currentItems: [FlowItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        var currentY: CGFloat = 0

        for index in subviews.indices {
            let measuredSize = subviews[index].sizeThatFits(.unspecified)
            let itemSize = CGSize(
                width: min(measuredSize.width, availableWidth),
                height: measuredSize.height
            )
            let nextWidth = currentItems.isEmpty
                ? itemSize.width
                : currentWidth + horizontalSpacing + itemSize.width

            if nextWidth > availableWidth, !currentItems.isEmpty {
                rows.append(FlowRow(y: currentY, height: currentHeight, items: currentItems))
                currentY += currentHeight + verticalSpacing
                currentItems = [FlowItem(index: index, size: itemSize)]
                currentWidth = itemSize.width
                currentHeight = itemSize.height
            } else {
                currentItems.append(FlowItem(index: index, size: itemSize))
                currentWidth = nextWidth
                currentHeight = max(currentHeight, itemSize.height)
            }
        }

        if !currentItems.isEmpty {
            rows.append(FlowRow(y: currentY, height: currentHeight, items: currentItems))
        }

        return rows
    }
}

private struct FlowRow {
    let y: CGFloat
    let height: CGFloat
    let items: [FlowItem]
}

private struct FlowItem {
    let index: Int
    let size: CGSize
}

private extension MainSearchKind {
    var historyIconSystemName: String {
        switch self {
        case .anime:
            "play.rectangle"
        case .manga:
            "book.closed"
        case .character:
            "person.crop.circle"
        case .people:
            "person.wave.2"
        }
    }
}

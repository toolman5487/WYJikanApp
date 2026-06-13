//
//  MainSearchHistoryFlowLayout.swift
//  WYJikanApp
//

import SwiftUI

struct MainSearchHistoryFlowLayout: Layout {
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

    private func rows(in maxWidth: CGFloat, subviews: Subviews) -> [MainSearchHistoryFlowRow] {
        guard !subviews.isEmpty else { return [] }

        let availableWidth = max(maxWidth, 0)
        var rows: [MainSearchHistoryFlowRow] = []
        var currentItems: [MainSearchHistoryFlowItem] = []
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
                rows.append(
                    MainSearchHistoryFlowRow(
                        y: currentY,
                        height: currentHeight,
                        items: currentItems
                    )
                )
                currentY += currentHeight + verticalSpacing
                currentItems = [MainSearchHistoryFlowItem(index: index, size: itemSize)]
                currentWidth = itemSize.width
                currentHeight = itemSize.height
            } else {
                currentItems.append(MainSearchHistoryFlowItem(index: index, size: itemSize))
                currentWidth = nextWidth
                currentHeight = max(currentHeight, itemSize.height)
            }
        }

        if !currentItems.isEmpty {
            rows.append(
                MainSearchHistoryFlowRow(
                    y: currentY,
                    height: currentHeight,
                    items: currentItems
                )
            )
        }

        return rows
    }
}

private struct MainSearchHistoryFlowRow {
    let y: CGFloat
    let height: CGFloat
    let items: [MainSearchHistoryFlowItem]
}

private struct MainSearchHistoryFlowItem {
    let index: Int
    let size: CGSize
}

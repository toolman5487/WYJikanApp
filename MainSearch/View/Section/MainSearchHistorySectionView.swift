//
//  MainSearchHistorySectionView.swift
//  WYJikanApp
//

import SwiftUI

struct MainSearchHistorySectionView: View {
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

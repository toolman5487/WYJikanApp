//
//  MainNewsSourceFilterBarView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsSourceFilterBarView: View {
    let filters: [MainNewsSourceFilter]
    let selection: MainNewsSourceFilter
    let onSelect: (MainNewsSourceFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            onSelect(filter)
                        }
                    } label: {
                        filterChip(filter)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func filterChip(_ filter: MainNewsSourceFilter) -> some View {
        let isSelected = selection == filter

        return Label(filter.title, systemImage: filter.systemImageName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? ThemeColor.textPrimary : ThemeColor.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(
                Capsule()
                    .fill(isSelected ? ThemeColor.sakura.opacity(0.32) : Color(.secondarySystemBackground))
            )
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? ThemeColor.sakura.opacity(0.55) : Color(.separator), lineWidth: 1)
            }
    }
}

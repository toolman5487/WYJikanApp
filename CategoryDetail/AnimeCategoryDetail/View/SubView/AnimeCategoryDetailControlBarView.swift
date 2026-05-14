//
//  AnimeCategoryDetailControlBarView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct AnimeCategoryDetailControlBarView: View {
    @Binding var selectedSort: AnimeCategoryFilter.Sort
    @Binding var selectedFormat: AnimeCategoryFilter.Format

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("探索條件")
                .font(.headline)
                .foregroundStyle(ThemeColor.textPrimary)

            HStack(spacing: 12) {
                Menu {
                    ForEach(AnimeCategoryFilter.Sort.allCases) { option in
                        Button(option.title) {
                            selectedSort = option
                        }
                    }
                } label: {
                    controlChip(
                        title: "排序：\(selectedSort.title)",
                        systemImage: "arrow.up.arrow.down"
                    )
                }

                Menu {
                    ForEach(AnimeCategoryFilter.Format.allCases) { option in
                        Button(option.title) {
                            selectedFormat = option
                        }
                    }
                } label: {
                    controlChip(
                        title: "形式：\(selectedFormat.title)",
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
            }
        }
    }

    private func controlChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(ThemeColor.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}

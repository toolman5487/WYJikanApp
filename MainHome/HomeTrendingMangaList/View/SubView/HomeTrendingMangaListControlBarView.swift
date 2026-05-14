//
//  HomeTrendingMangaListControlBarView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/6.
//

import SwiftUI

struct HomeTrendingMangaListControlBarContainerView: View {
    @Binding var selectedSort: HomeTrendingMangaListSort
    @Binding var selectedFormat: HomeTrendingMangaListFormat

    var body: some View {
        VStack(spacing: 12) {
            HomeTrendingMangaListControlBarView(
                selectedSort: $selectedSort,
                selectedFormat: $selectedFormat
            )
            .padding(.horizontal, 16)

            Divider()
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }
}

struct HomeTrendingMangaListControlBarView: View {
    @Binding var selectedSort: HomeTrendingMangaListSort
    @Binding var selectedFormat: HomeTrendingMangaListFormat

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(HomeTrendingMangaListSort.allCases) { option in
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
                ForEach(HomeTrendingMangaListFormat.allCases) { option in
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

            Spacer(minLength: 0)
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

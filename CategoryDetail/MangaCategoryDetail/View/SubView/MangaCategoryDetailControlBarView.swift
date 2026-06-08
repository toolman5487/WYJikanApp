//
//  MangaCategoryDetailControlBarView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct MangaCategoryDetailControlBarContainerView: View {

    // MARK: - Properties

    @Binding var selectedSort: MangaCategoryFilter.Sort
    @Binding var selectedFormat: MangaCategoryFilter.Format

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            MangaCategoryDetailControlBarView(
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

struct MangaCategoryDetailControlBarView: View {

    // MARK: - Properties

    @Binding var selectedSort: MangaCategoryFilter.Sort
    @Binding var selectedFormat: MangaCategoryFilter.Format

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Menu {
                    ForEach(MangaCategoryFilter.Sort.allCases) { option in
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
                    ForEach(MangaCategoryFilter.Format.allCases) { option in
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
        .scrollClipDisabled()
    }

    // MARK: - Private Methods

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

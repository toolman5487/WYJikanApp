//
//  HomeTrendingAnimeListControlBarView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListControlBarContainerView: View {

    // MARK: - Properties

    let items: [HomeTrendingAnimeListSortChipItem]
    let onSelectSort: (HomeTrendingAnimeListSort) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            HomeTrendingAnimeListControlBarView(
                items: items,
                onSelectSort: onSelectSort
            )
            .padding(.horizontal, 16)

            Divider()
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }
}

struct HomeTrendingAnimeListControlBarView: View {

    // MARK: - Properties

    let items: [HomeTrendingAnimeListSortChipItem]
    let onSelectSort: (HomeTrendingAnimeListSort) -> Void

    // MARK: - Body

    var body: some View {
        CapsuleFilterBarView(
            tags: items,
            title: { $0.title },
            systemImageName: { $0.systemImageName },
            selection: selectedItemBinding,
            onTap: { item in
                onSelectSort(item.sort)
            }
        )
    }

    // MARK: - Private Methods

    private var selectedItemBinding: Binding<HomeTrendingAnimeListSortChipItem> {
        Binding(
            get: {
                items.first(where: \.isSelected) ?? items.first!
            },
            set: { newValue in
                onSelectSort(newValue.sort)
            }
        )
    }
}

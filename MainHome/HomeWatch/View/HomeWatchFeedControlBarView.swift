//
//  HomeWatchFeedControlBarView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI

// MARK: - HomeWatchFeedControlBarContainerView

struct HomeWatchFeedControlBarContainerView: View {

    // MARK: - Properties

    let items: [HomeWatchFeedChipItem]
    let onSelectFeed: (HomeWatchFeedKind) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            HomeWatchFeedControlBarView(
                items: items,
                onSelectFeed: onSelectFeed
            )
            .padding(.horizontal, 16)

            Divider()
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }
}

struct HomeWatchFeedControlBarView: View {

    // MARK: - Properties

    let items: [HomeWatchFeedChipItem]
    let onSelectFeed: (HomeWatchFeedKind) -> Void

    // MARK: - Body

    var body: some View {
        CapsuleFilterBarView(
            tags: items,
            title: { $0.title },
            systemImageName: { $0.systemImageName },
            selection: selectedItemBinding,
            onTap: { item in
                onSelectFeed(item.feed)
            }
        )
    }

    // MARK: - Private Methods

    private var selectedItemBinding: Binding<HomeWatchFeedChipItem> {
        Binding(
            get: {
                items.first(where: \.isSelected)
                    ?? items.first
                    ?? HomeWatchFeedChipItem(feed: .latestEpisodes, isSelected: true)
            },
            set: { newValue in
                onSelectFeed(newValue.feed)
            }
        )
    }
}

//
//  FavoriteStatusSyncBridge.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import SwiftData
import SwiftUI

struct FavoriteStatusSyncBridge: View {
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @Query(sort: \MyListCollectionItem.addedAt, order: .reverse)
    private var items: [MyListCollectionItem]

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                favoriteStatusStore.sync(items: items)
            }
            .onChange(of: items) { _, newItems in
                favoriteStatusStore.sync(items: newItems)
            }
    }
}

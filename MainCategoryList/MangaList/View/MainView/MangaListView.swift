//
//  MangaListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct MangaListView: View {

    // MARK: - Properties

    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @ObservedObject var viewModel: MangaListViewModel

    // MARK: - Body

    var body: some View {
        MainView(
            viewModel: viewModel,
            favoriteIDs: favoriteStatusStore.favoriteIDs(for: .manga)
        )
    }
}

// MARK: - MainView

private struct MainView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: MangaListViewModel
    let favoriteIDs: Set<Int>

    // MARK: - Body

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
            RandomMangaSectionView(
                viewModel: viewModel.randomHeroViewModel,
                favoriteIDs: favoriteIDs
            )
            GenreMangaListContainerView(
                viewModel: viewModel.genreMangaViewModel,
                favoriteIDs: favoriteIDs
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            MangaListView(viewModel: MangaListViewModel())
                .environmentObject(FavoriteStatusStore())
                .padding(.horizontal)
        }
    }
}

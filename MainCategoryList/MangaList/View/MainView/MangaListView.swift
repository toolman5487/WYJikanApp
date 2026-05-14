//
//  MangaListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct MangaListView: View {
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @ObservedObject var viewModel: MangaListViewModel

    var body: some View {
        MainView(
            viewModel: viewModel,
            favoriteIDs: favoriteStatusStore.favoriteIDs(for: .manga)
        )
            .onAppear {
                viewModel.loadIfNeeded()
            }
    }
}

private struct MainView: View {
    @ObservedObject var viewModel: MangaListViewModel
    let favoriteIDs: Set<Int>

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

#Preview {
    NavigationStack {
        ScrollView {
            MangaListView(viewModel: MangaListViewModel())
                .environmentObject(FavoriteStatusStore())
                .padding(.horizontal)
        }
    }
}

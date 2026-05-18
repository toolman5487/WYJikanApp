//
//  AnimeListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct AnimeListView: View {

    // MARK: - Properties

    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @ObservedObject var viewModel: AnimeListViewModel

    // MARK: - Body

    var body: some View {
        MainView(
            viewModel: viewModel,
            favoriteIDs: favoriteStatusStore.favoriteIDs(for: .anime)
        )
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }
}

// MARK: - MainView

private struct MainView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: AnimeListViewModel
    let favoriteIDs: Set<Int>

    // MARK: - Body

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
            RandomHeroSectionView(
                viewModel: viewModel.randomHeroViewModel,
                favoriteIDs: favoriteIDs
            )
            GenreAnimeListContainerView(
                viewModel: viewModel.genreAnimeViewModel,
                favoriteIDs: favoriteIDs
            )
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            AnimeListView(viewModel: AnimeListViewModel())
                .environmentObject(FavoriteStatusStore())
                .padding(.horizontal)
        }
    }
}

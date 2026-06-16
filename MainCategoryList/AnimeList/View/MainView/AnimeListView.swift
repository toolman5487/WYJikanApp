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
    @State private var selectedGenre: AnimeListGenreDTO?

    // MARK: - Body

    var body: some View {
        MainView(
            viewModel: viewModel,
            favoriteIDs: favoriteStatusStore.favoriteIDs(for: .anime),
            onSelectGenre: { selectedGenre = $0 }
        )
        .navigationDestination(item: $selectedGenre) { genre in
            AnimeCategoryDetailView(genre: genre)
        }
    }
}

// MARK: - MainView

private struct MainView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: AnimeListViewModel
    let favoriteIDs: Set<Int>
    let onSelectGenre: (AnimeListGenreDTO) -> Void

    // MARK: - Body

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
            RandomHeroSectionView(
                viewModel: viewModel.randomHeroViewModel,
                favoriteIDs: favoriteIDs
            )
            GenreAnimeListContainerView(
                viewModel: viewModel.genreAnimeViewModel,
                favoriteIDs: favoriteIDs,
                onSelectGenre: onSelectGenre
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            AnimeListView(viewModel: AppDependencies.live.makeMainCategoryListViewModel().animeListViewModel)
                .environmentObject(FavoriteStatusStore())
                .padding(.horizontal)
        }
    }
}

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
    @State private var selectedGenre: MangaListGenreDTO?

    // MARK: - Body

    var body: some View {
        MainView(
            viewModel: viewModel,
            favoriteIDs: favoriteStatusStore.favoriteIDs(for: .manga),
            onSelectGenre: { selectedGenre = $0 }
        )
        .navigationDestination(item: $selectedGenre) { genre in
            MangaCategoryDetailView(genre: genre)
        }
    }
}

// MARK: - MainView

private struct MainView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: MangaListViewModel
    let favoriteIDs: Set<Int>
    let onSelectGenre: (MangaListGenreDTO) -> Void

    // MARK: - Body

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 4, pinnedViews: [.sectionHeaders]) {
            GenreMangaListContainerView(
                viewModel: viewModel.genreMangaViewModel,
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
            MangaListView(viewModel: AppDependencies.live.makeMainCategoryListViewModel().mangaListViewModel)
                .environmentObject(FavoriteStatusStore())
                .padding(.horizontal)
        }
    }
}

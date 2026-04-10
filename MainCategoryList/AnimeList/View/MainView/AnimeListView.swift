//
//  AnimeListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct AnimeListView: View {
    @ObservedObject var viewModel: AnimeListViewModel

    var body: some View {
        MainView(viewModel: viewModel)
            .onAppear {
                viewModel.loadIfNeeded()
            }
    }
}

// MARK: - MainView

private struct MainView: View {
    @ObservedObject var viewModel: AnimeListViewModel

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            RandomHeroSectionView(viewModel: viewModel.randomHeroViewModel)
            GenreAnimeListContainerView(viewModel: viewModel.genreAnimeViewModel)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            AnimeListView(viewModel: AnimeListViewModel())
                .padding(.horizontal)
        }
    }
}

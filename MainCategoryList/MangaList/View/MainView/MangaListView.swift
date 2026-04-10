//
//  MangaListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct MangaListView: View {
    @ObservedObject var viewModel: MangaListViewModel

    var body: some View {
        MainView(viewModel: viewModel)
            .onAppear {
                viewModel.loadIfNeeded()
            }
    }
}

private struct MainView: View {
    @ObservedObject var viewModel: MangaListViewModel

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            RandomMangaSectionView(viewModel: viewModel.randomHeroViewModel)
            GenreMangaListContainerView(viewModel: viewModel.genreMangaViewModel)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            MangaListView(viewModel: MangaListViewModel())
                .padding(.horizontal)
        }
    }
}

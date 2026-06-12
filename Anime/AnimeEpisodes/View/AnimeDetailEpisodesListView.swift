//
//  AnimeDetailEpisodesListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import SwiftUI

struct AnimeDetailEpisodesListView: View {
    let malId: Int
    let animeTitle: String

    var body: some View {
        AnimeDetailEpisodesListConfiguredView(malId: malId, animeTitle: animeTitle)
    }
}

private struct AnimeDetailEpisodesListConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    let malId: Int
    let animeTitle: String

    var body: some View {
        AnimeDetailEpisodesListBodyView(
            malId: malId,
            animeTitle: animeTitle,
            dependencies: dependencies
        )
    }
}

private struct AnimeDetailEpisodesListBodyView: View {
    let malId: Int
    let animeTitle: String

    @StateObject private var viewModel: AnimeDetailEpisodesListViewModel

    init(malId: Int, animeTitle: String, dependencies: AppDependencies) {
        self.malId = malId
        self.animeTitle = animeTitle
        _viewModel = StateObject(
            wrappedValue: dependencies.makeAnimeDetailEpisodesListViewModel(malId: malId)
        )
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                ErrorMessageView(state: .emptyCollection("目前沒有可顯示的集數資料"), height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                ErrorMessageView(state: .network(message), height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .content:
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.episodeRows) { row in
                            AnimeDetailEpisodeRowView(
                                row: row
                            ) {
                                Task {
                                    await viewModel.toggleEpisodeDetail(for: row.id)
                                }
                            }
                            .equatable()
                        }

                        AnimeDetailEpisodesLoadMoreFooterView(
                            state: viewModel.loadMoreState,
                            onLoadMore: viewModel.loadMore,
                            onRetry: viewModel.retryLoadMore
                        )
                    }
                    .animation(.easeInOut(duration: 0.18), value: viewModel.episodeRows)
                    .padding()
                }
            }
        }
        .navigationTitle("\(animeTitle) 集數")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: malId) {
            await viewModel.loadIfNeeded()
        }
    }
}

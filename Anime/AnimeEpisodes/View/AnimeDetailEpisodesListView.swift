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

    @StateObject private var viewModel: AnimeDetailEpisodesListViewModel

    init(
        malId: Int,
        animeTitle: String,
        service: any AnimeDetailServicing = AnimeDetailService()
    ) {
        self.malId = malId
        self.animeTitle = animeTitle
        _viewModel = StateObject(
            wrappedValue: AnimeDetailEpisodesListViewModel(
                malId: malId,
                service: service
            )
        )
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                ErrorMessageView(message: "目前沒有可顯示的集數資料", height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                ErrorMessageView(message: message, height: 200)
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

                        if viewModel.hasNextPage {
                            Button {
                                Task { await viewModel.loadMore() }
                            } label: {
                                HStack {
                                    Spacer(minLength: 0)
                                    if viewModel.isLoadingMore {
                                        ProgressView()
                                    } else {
                                        Text("載入更多集數")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    Spacer(minLength: 0)
                                }
                                .foregroundStyle(ThemeColor.textPrimary)
                                .frame(minHeight: 44)
                                .background(ThemeColor.sakura)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 16,
                                        style: .continuous
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
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

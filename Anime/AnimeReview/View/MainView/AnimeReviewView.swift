//
//  AnimeReviewView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewView: View {
    let malId: Int
    let animeTitle: String?

    init(malId: Int, animeTitle: String? = nil) {
        self.malId = malId
        self.animeTitle = animeTitle
    }

    var body: some View {
        AnimeReviewConfiguredView(malId: malId, animeTitle: animeTitle)
    }
}

private struct AnimeReviewConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    let malId: Int
    let animeTitle: String?

    var body: some View {
        AnimeReviewBodyView(
            malId: malId,
            animeTitle: animeTitle,
            dependencies: dependencies
        )
    }
}

private struct AnimeReviewBodyView: View {
    let malId: Int
    let animeTitle: String?

    @StateObject private var viewModel: AnimeReviewViewModel

    init(malId: Int, animeTitle: String?, dependencies: AppDependencies) {
        self.malId = malId
        self.animeTitle = animeTitle
        _viewModel = StateObject(wrappedValue: dependencies.makeAnimeReviewViewModel(malId: malId))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case let .error(failure):
                ErrorMessageRetryCardView(
                    state: ErrorMessageView.State(failure: failure),
                    title: "評論暫時載入失敗",
                    retryTitle: "重新載入"
                ) {
                    Task(priority: .userInitiated) { await viewModel.load() }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loading:
                AnimeReviewListSkeletonView()
            case .empty:
                FeatureEmptyStateCardView(
                    emptyState: .emptyCollection(
                        title: "尚無評論",
                        message: "目前還沒有人留下評價。"
                    ),
                    minHeight: 0
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .content:
                AnimeReviewListView(viewModel: viewModel)
            }
        }
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: malId, priority: .userInitiated) {
            await viewModel.screenDidAppear()
        }
        .onDisappear {
            viewModel.screenDidDisappear()
        }
    }

    private var navigationTitleText: String {
        let trimmed = animeTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "用戶評論" : trimmed
    }
}

#Preview {
    NavigationStack {
        AnimeReviewView(malId: 52991, animeTitle: "葬送的芙莉蓮")
    }
}

//
//  MangaReviewView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MangaReviewView: View {
    let malId: Int
    let mangaTitle: String?

    init(malId: Int, mangaTitle: String? = nil) {
        self.malId = malId
        self.mangaTitle = mangaTitle
    }

    var body: some View {
        MangaReviewConfiguredView(malId: malId, mangaTitle: mangaTitle)
    }
}

private struct MangaReviewConfiguredView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.requestParentTab) private var requestParentTab
    let malId: Int
    let mangaTitle: String?

    var body: some View {
        MangaReviewBodyView(
            malId: malId,
            mangaTitle: mangaTitle,
            parentTab: requestParentTab,
            dependencies: dependencies
        )
    }
}

private struct MangaReviewBodyView: View {
    let malId: Int
    let mangaTitle: String?

    @StateObject private var viewModel: MangaReviewViewModel

    init(
        malId: Int,
        mangaTitle: String?,
        parentTab: JikanAPIRequestScope,
        dependencies: AppDependencies
    ) {
        self.malId = malId
        self.mangaTitle = mangaTitle
        _viewModel = StateObject(
            wrappedValue: dependencies.makeMangaReviewViewModel(
                malId: malId,
                parentTab: parentTab
            )
        )
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
                MangaReviewListSkeletonView()
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
                MangaReviewListView(viewModel: viewModel)
            }
        }
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .requestScreenTabLifecycle(viewModel: viewModel)
    }

    private var navigationTitleText: String {
        let trimmed = mangaTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "用戶評論" : trimmed
    }
}

#Preview {
    NavigationStack {
        MangaReviewView(malId: 1, mangaTitle: "Monster")
    }
}

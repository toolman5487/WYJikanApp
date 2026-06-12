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
    let malId: Int
    let mangaTitle: String?

    var body: some View {
        MangaReviewBodyView(
            malId: malId,
            mangaTitle: mangaTitle,
            dependencies: dependencies
        )
    }
}

private struct MangaReviewBodyView: View {
    let malId: Int
    let mangaTitle: String?

    @StateObject private var viewModel: MangaReviewViewModel

    init(malId: Int, mangaTitle: String?, dependencies: AppDependencies) {
        self.malId = malId
        self.mangaTitle = mangaTitle
        _viewModel = StateObject(wrappedValue: dependencies.makeMangaReviewViewModel(malId: malId))
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case let .error(failure):
                ErrorMessageView(state: ErrorMessageView.State(failure: failure), height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loading:
                MangaReviewListSkeletonView()
            case .empty:
                AnimeReviewEmptyStateView()
            case .content:
                MangaReviewListView(viewModel: viewModel)
            }
        }
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: malId) {
            await viewModel.load()
        }
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

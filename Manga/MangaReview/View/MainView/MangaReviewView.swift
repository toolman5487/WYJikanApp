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

    @StateObject private var viewModel: MangaReviewViewModel

    init(malId: Int, mangaTitle: String? = nil, service: MangaReviewServicing = MangaReviewService()) {
        self.malId = malId
        self.mangaTitle = mangaTitle
        _viewModel = StateObject(wrappedValue: MangaReviewViewModel(malId: malId, service: service))
    }

    var body: some View {
        Group {
            if let message = viewModel.errorMessage {
                ErrorMessageView(message: message, height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isLoading, viewModel.reviews.isEmpty {
                MangaReviewListSkeletonView()
            } else if viewModel.reviews.isEmpty {
                AnimeReviewEmptyStateView()
            } else {
                MangaReviewListView(viewModel: viewModel)
            }
        }
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: malId) {
            await viewModel.load()
        }
    }

    // MARK: - Private

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

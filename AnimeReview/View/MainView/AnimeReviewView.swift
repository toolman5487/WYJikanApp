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

    @StateObject private var viewModel: AnimeReviewViewModel

    init(malId: Int, animeTitle: String? = nil, service: AnimeReviewServicing = AnimeReviewService()) {
        self.malId = malId
        self.animeTitle = animeTitle
        _viewModel = StateObject(wrappedValue: AnimeReviewViewModel(malId: malId, service: service))
    }

    var body: some View {
        Group {
            if let message = viewModel.errorMessage {
                ErrorMessageView(message: message, height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isLoading, viewModel.reviews.isEmpty {
                reviewListSkeleton
            } else if viewModel.reviews.isEmpty {
                AnimeReviewEmptyStateView()
            } else {
                AnimeReviewListView(viewModel: viewModel)
            }
        }
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: malId) {
            await viewModel.load()
        }
    }

    // MARK: - Private

    private static let skeletonRowCount = 6

    private var reviewListSkeleton: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(0..<Self.skeletonRowCount, id: \.self) { index in
                    if index > 0 {
                        Divider()
                    }
                    AnimeReviewRowSkeletonView()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
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

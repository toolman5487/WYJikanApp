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
            switch viewModel.screenState {
            case let .error(message):
                ErrorMessageView(message: message, height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loading:
                AnimeReviewListSkeletonView()
            case .empty:
                AnimeReviewEmptyStateView()
            case .content:
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

//
//  AnimeReviewRowView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewRowView: View {

    // MARK: - Properties

    @StateObject private var reviewTranslationViewModel = SynopsisTranslationViewModel(
        context: .animeReview
    )

    let viewModel: AnimeReviewViewModel
    let entry: AnimeReviewEntryDTO

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AnimeReviewRowHeaderView(viewModel: viewModel, entry: entry)
            AnimeReviewRowBadgesView(entry: entry)
            AnimeReviewRowTagsView(labels: viewModel.tagLabels(for: entry))

            ReviewTranslationContentView(
                originalText: reviewBodyText,
                translationState: reviewTranslationViewModel.state,
                onTranslate: {
                    reviewTranslationViewModel.requestTranslation(
                        for: reviewBodyText,
                        emptyFailureMessage: "沒有可翻譯的評論內容。"
                    )
                }
            )

            if let url = reviewDetailURL {
                MALWorkPageOpenButton(url: url)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: entry.id) { _, _ in
            reviewTranslationViewModel.reset()
        }
        .onDisappear {
            reviewTranslationViewModel.cancel()
        }
    }

    // MARK: - Private

    private var reviewBodyText: String {
        viewModel.bodyDisplayText(for: entry)
    }

    private var reviewDetailURL: URL? {
        guard let link = entry.url?.trimmingCharacters(in: .whitespacesAndNewlines), !link.isEmpty,
              let url = URL(string: link)
        else { return nil }
        return url
    }
}

//
//  MangaReviewRowView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MangaReviewRowView: View {

    // MARK: - Properties

    @StateObject private var reviewTranslationViewModel = SynopsisTranslationViewModel(
        context: .mangaReview
    )

    let viewModel: MangaReviewViewModel
    let entry: MangaReviewEntryDTO

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MangaReviewRowHeaderView(viewModel: viewModel, entry: entry)
            MangaReviewRowBadgesView(entry: entry)
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

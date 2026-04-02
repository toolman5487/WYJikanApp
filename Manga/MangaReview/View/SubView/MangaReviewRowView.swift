//
//  MangaReviewRowView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MangaReviewRowView: View {

    let viewModel: MangaReviewViewModel
    let entry: MangaReviewEntryDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MangaReviewRowHeaderView(viewModel: viewModel, entry: entry)
            MangaReviewRowBadgesView(entry: entry)
            AnimeReviewRowTagsView(labels: viewModel.tagLabels(for: entry))
            Text(viewModel.bodyDisplayText(for: entry))
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let url = reviewDetailURL {
                AnimeReviewRowMALButton(url: url)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Private

    private var reviewDetailURL: URL? {
        guard let link = entry.url?.trimmingCharacters(in: .whitespacesAndNewlines), !link.isEmpty,
              let url = URL(string: link)
        else { return nil }
        return url
    }
}

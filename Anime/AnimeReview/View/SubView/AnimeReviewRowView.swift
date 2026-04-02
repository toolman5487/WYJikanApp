//
//  AnimeReviewRowView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewRowView: View {

    let viewModel: AnimeReviewViewModel
    let entry: AnimeReviewEntryDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AnimeReviewRowHeaderView(viewModel: viewModel, entry: entry)
            AnimeReviewRowBadgesView(entry: entry)
            AnimeReviewRowTagsView(labels: viewModel.tagLabels(for: entry))
            Text(viewModel.bodyDisplayText(for: entry))
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let url = reviewDetailURL {
                MALWorkPageOpenButton(url: url)
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

//
//  AnimeReviewRowHeaderView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewRowHeaderView: View {

    let viewModel: AnimeReviewViewModel
    let entry: AnimeReviewEntryDTO

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            reviewAvatar
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.username(for: entry))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                if let dateText = viewModel.dateDisplayText(for: entry) {
                    Text(dateText)
                        .font(.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let scoreText = viewModel.scoreDisplayText(for: entry) {
                Text(scoreText)
                    .font(.headline)
                    .foregroundStyle(ThemeColor.sakura)
            }
        }
    }

    // MARK: - Private

    @ViewBuilder
    private var reviewAvatar: some View {
        if let url = viewModel.userAvatarURL(for: entry) {
            RemotePosterImageView(url: url)
        } else {
            ZStack {
                Color(.systemGray5)
                Image(systemName: "person.fill")
                    .foregroundStyle(Color(.systemGray))
            }
        }
    }
}

//
//  AnimeReviewRowView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewRowView: View {
    
    @Environment(\.openURL) private var openURL
    
    let viewModel: AnimeReviewViewModel
    let entry: AnimeReviewEntryDTO
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            if entry.isSpoiler == true {
                Text("可能含有劇透")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            }
            if entry.isPreliminary == true {
                Text("觀看進度未滿")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(ThemeColor.textSecondary)
            }
            if !reviewTagLabels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(reviewTagLabels.enumerated()), id: \.offset) { _, tag in
                            Text(tag)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(ThemeColor.textPrimary)
                                .lineLimit(1)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 44)
                                .background(ThemeColor.sakura)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            Text(viewModel.bodyDisplayText(for: entry))
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let link = entry.url?.trimmingCharacters(in: .whitespacesAndNewlines),
               !link.isEmpty,
               let url = URL(string: link) {
                Button {
                    openURL(url)
                } label: {
                    Text("在 MyAnimeList 上查看")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .tint(ThemeColor.textPrimary)
                .background(ThemeColor.sakura)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Private
    
    private var reviewTagLabels: [String] {
        viewModel.tagLabels(for: entry)
    }
    
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

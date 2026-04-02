//
//  MangaDetailHeaderSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailHeaderSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            posterView
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.displayTitle(for: manga))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)
                if let english = manga.titleEnglish, !english.isEmpty {
                    Text(english)
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
                if let sensitiveContent = viewModel.sensitiveContentText(for: manga) {
                    Text(sensitiveContent)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ThemeColor.sakura)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var posterView: some View {
        if let url = viewModel.posterURL(for: manga) {
            RemotePosterImageView(url: url)
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                .frame(width: 132, height: 196)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

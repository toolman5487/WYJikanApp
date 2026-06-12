//
//  AnimeDetailHeaderSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailHeaderSectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO
    let onTapPoster: (() -> Void)?

    init(
        viewModel: AnimeDetailViewModel,
        anime: AnimeDetailDTO,
        onTapPoster: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.anime = anime
        self.onTapPoster = onTapPoster
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            posterView
            VStack(alignment: .leading, spacing: 8) {
                DetailCopyableText(
                    text: viewModel.displayTitle(for: anime),
                    style: .primary
                )
                if let english = anime.titleEnglish, !english.isEmpty {
                    DetailCopyableText(text: english, style: .secondary)
                }
                if let sensitiveContent = viewModel.sensitiveContentText(for: anime) {
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
        if let url = viewModel.posterURL(for: anime) {
            RemotePosterImageView(
                url: url,
                fixedSize: CGSize(width: 132, height: 196)
            )
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                .frame(width: 132, height: 196)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(Rectangle())
                .onTapGesture {
                    onTapPoster?()
                }
        }
    }
}

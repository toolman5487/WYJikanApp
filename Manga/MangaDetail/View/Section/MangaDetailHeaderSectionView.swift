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
    let onTapPoster: (() -> Void)?

    init(
        viewModel: MangaDetailViewModel,
        manga: MangaDetailDTO,
        onTapPoster: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.manga = manga
        self.onTapPoster = onTapPoster
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            posterView
            VStack(alignment: .leading, spacing: 8) {
                DetailCopyableText(
                    text: viewModel.displayTitle(for: manga),
                    style: .primary
                )
                if let english = manga.titleEnglish, !english.isEmpty {
                    DetailCopyableText(text: english, style: .secondary)
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
                .contentShape(Rectangle())
                .onTapGesture {
                    onTapPoster?()
                }
        }
    }
}

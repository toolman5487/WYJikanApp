//
//  CharacterDetailHeaderSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailHeaderSectionView: View {
    let viewModel: CharacterDetailViewModel
    let character: CharacterDetailDTO

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            posterView

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.displayName(for: character))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)

                if let englishName = viewModel.englishName(for: character) {
                    Text(englishName)
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textSecondary)
                }

                Text("\(viewModel.favoritesText(for: character)) 收藏")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ThemeColor.sakura)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var posterView: some View {
        if let url = viewModel.posterURL(for: character) {
            RemotePosterImageView(url: url)
                .aspectRatio(2.0 / 3.0, contentMode: .fill)
                .frame(width: 132, height: 196)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(width: 132, height: 196)
                .overlay {
                    Image(systemName: "person.crop.rectangle")
                        .font(.title2)
                        .foregroundStyle(ThemeColor.textTertiary)
                }
        }
    }
}

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

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            posterView
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.displayTitle(for: anime))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)
                
                if let english = anime.titleEnglish, !english.isEmpty {
                    Text(english)
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
            }
            
            Spacer(minLength: 0)
        }
    }
    
    @ViewBuilder
    private var posterView: some View {
        if let url = viewModel.posterURL(for: anime) {
            RemotePosterImageView(url: url)
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                .frame(width: 132, height: 196)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

struct AnimeDetailHeaderSectionSkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            BannerSkeletonView()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .frame(width: 132, height: 196)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonBar(width: nil, height: 26, cornerRadius: 8)
                SkeletonBar(width: 200, height: 18, cornerRadius: 8)
            }

            Spacer(minLength: 0)
        }
    }
}

//
//  AnimeDetailTrailerSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI
import SDWebImageSwiftUI

struct AnimeDetailTrailerSectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO

    @Environment(\.openURL) private var openURL
    @State private var showsPlayer = false

    var body: some View {
        if let embedURL = viewModel.trailerEmbedURL(for: anime) {
            AnimeDetailSectionCard("預告片") {
                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        if showsPlayer {
                            YouTubeEmbedWebView(url: embedURL)
                        } else {
                            trailerThumbnailView
                            Button {
                                showsPlayer = true
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 56))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .shadow(radius: 8)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if let watchURL = viewModel.trailerWatchURL(for: anime) {
                        Button {
                            openURL(watchURL)
                        } label: {
                            Text("在 YouTube 開啟")
                                .font(.subheadline.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .foregroundStyle(ThemeColor.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .background(ThemeColor.sakura)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .onChange(of: anime.malId) { _, _ in
                showsPlayer = false
            }
        }
    }

    private var trailerThumbnailView: some View {
        Group {
            if let thumbnailURL = viewModel.trailerThumbnailURL(for: anime) {
                WebImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color(.systemGray5)
                }
            } else {
                Color(.systemGray5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

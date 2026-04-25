//
//  RandomHeroCardView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct RandomHeroCardView: View {
    let pick: AnimeListRandomDTO?
    let isDrawing: Bool
    var errorMessage: String? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let url = pick?.posterURL {
                    RemotePosterImageView(url: url)
                } else {
                    Color(.secondarySystemFill)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .clipped()

            PosterTextGradientOverlayView()
                .frame(height: 260)

            VStack(alignment: .leading, spacing: 6) {
                if let pick {
                    Text(pick.displayTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if let type = pick.type, !type.isEmpty {
                            chip(text: type)
                        }
                        if let score = pick.score {
                            chip(text: String(format: "★ %.2f", score))
                        }
                    }
                } else if let errorMessage {
                    Text("載入失敗")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ThemeColor.textPrimary)
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .overlay(alignment: .topTrailing) {
            if let malId = pick?.id {
                MyListCollectionStatusBadgeView(malId: malId, mediaKind: .anime)
                    .padding(10)
            }
        }
        .overlay {
            if isDrawing {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                ProgressView()
                    .tint(ThemeColor.sakura)
            }
        }
    }

    private func chip(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(ThemeColor.textPrimary.opacity(0.22))
            .clipShape(Capsule())
    }
}

#Preview {
    RandomHeroCardView(
        pick: AnimeListRandomDTO(
            malId: 1,
            title: "Sample",
            titleEnglish: nil,
            titleJapanese: "サンプル",
            synopsis: nil,
            type: "TV",
            score: 8.5,
            rank: nil,
            popularity: nil,
            members: nil,
            episodes: nil,
            images: nil,
            genres: nil
        ),
        isDrawing: false
    )
}

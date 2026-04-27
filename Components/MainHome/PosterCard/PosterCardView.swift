//
//  PosterCardView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct PosterCardView<ImageContent: View>: View {
    private static var cornerRadius: CGFloat { 16 }
    private static var rankPadding: CGFloat { 6 }

    let rank: Int?
    private let imageContent: ImageContent

    init(
        rank: Int? = nil,
        @ViewBuilder imageContent: () -> ImageContent
    ) {
        self.rank = rank
        self.imageContent = imageContent()
    }

    var body: some View {
        ZStack {
            imageContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.06))

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.75)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            if let rank {
                Text("#\(rank)")
                    .font(.caption.weight(.bold))
                    .padding(8)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .background(ThemeColor.sakuraGlassStrong)
                    .clipShape(Capsule())
                    .padding(Self.rankPadding)
            }
        }
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }
}

struct PosterCardMetadataOverlayView: View {
    let title: String
    let type: String?
    let score: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(2)

            HStack(spacing: 6) {
                if let type, !type.isEmpty {
                    chip(text: type)
                }
                if let score {
                    chip(text: String(format: "★ %.2f", score))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
    }

    private func chip(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial.opacity(0.72))
            .clipShape(Capsule())
    }
}

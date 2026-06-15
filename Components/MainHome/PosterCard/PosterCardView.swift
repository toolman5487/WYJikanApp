//
//  PosterCardView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

// MARK: - MainHomePosterCardMetrics

enum MainHomePosterCardMetrics {
    static let width: CGFloat = 160
    static let height: CGFloat = 240
    static let cornerRadius: CGFloat = 16

    static var size: CGSize {
        CGSize(width: width, height: height)
    }
}

// MARK: - PosterCardView

struct PosterCardView<ImageContent: View>: View {

    // MARK: - Properties

    private static var rankPadding: CGFloat { 6 }

    let rank: Int?
    private let imageContent: ImageContent

    // MARK: - Lifecycle

    init(
        rank: Int? = nil,
        @ViewBuilder imageContent: () -> ImageContent
    ) {
        self.rank = rank
        self.imageContent = imageContent()
    }

    // MARK: - Body

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
            rankBadge
        }
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: MainHomePosterCardMetrics.cornerRadius, style: .continuous))
    }

    // MARK: - Private Views

    @ViewBuilder
    private var rankBadge: some View {
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
}

// MARK: - PosterCardMetadataOverlayView

struct PosterCardMetadataOverlayView: View {

    // MARK: - Properties

    let title: String
    let type: String?
    let score: Double?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                if let type, !type.isEmpty {
                    chip(text: type)
                }
                if let score {
                    chip(text: String(format: "★ %.2f", score))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    // MARK: - Private Methods

    private func chip(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial.opacity(0.72))
            .clipShape(Capsule())
    }
}

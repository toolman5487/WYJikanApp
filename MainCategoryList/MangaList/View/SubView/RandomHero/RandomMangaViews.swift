//
//  RandomMangaViews.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import SwiftUI

struct RandomMangaSectionView: View {
    @ObservedObject var viewModel: RandomMangaViewModel

    var body: some View {
        let pick = viewModel.randomPick
        let isDrawing = viewModel.isDrawing
        let drawError = viewModel.drawError

        VStack(alignment: .leading, spacing: 12) {
            Group {
                if isDrawing, pick == nil {
                    RandomMangaSkeletonView()
                } else if let error = drawError, pick == nil {
                    RandomMangaCardView(
                        pick: nil,
                        isDrawing: false,
                        errorMessage: error
                    )
                } else {
                    RandomMangaCardView(
                        pick: pick,
                        isDrawing: isDrawing
                    )
                }
            }

            RandomMangaActionButtonsView(
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: pick?.malId,
                onDrawTap: viewModel.drawRandomManga
            )
        }
    }
}

private struct RandomMangaCardView: View {
    let pick: MangaListRandomDTO?
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

private struct RandomMangaActionButtonsView: View {
    let drawButtonTitle: String
    let canDraw: Bool
    let detailMalId: Int?
    let onDrawTap: () -> Void

    var body: some View {
        if let id = detailMalId {
            HStack(spacing: 12) {
                Button(action: onDrawTap) {
                    Text(drawButtonTitle)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
                .disabled(!canDraw)

                NavigationLink {
                    MangaDetailView(malId: id)
                } label: {
                    Text("查看詳情")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
            }
        } else {
            Button(action: onDrawTap) {
                Text(drawButtonTitle)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColor.sakura)
            .disabled(!canDraw)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct RandomMangaSkeletonView: View {
    var body: some View {
        BannerSkeletonView()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .frame(height: 260)
    }
}

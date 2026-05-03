//
//  RandomMangaViews.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import SwiftUI
import SDWebImageSwiftUI

struct RandomMangaSectionView: View {
    @ObservedObject var viewModel: RandomMangaViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今天抽這部")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ThemeColor.sakura)

                Text("不知道看什麼？試試手氣，隨機挖到下一部想追的漫畫作品。")
                    .font(.subheadline)
                    .foregroundStyle(ThemeColor.textSecondary)
            }

            switch viewModel.drawState {
            case .loading where viewModel.randomPick == nil:
                RandomMangaSkeletonView()
            case .failure(let error) where viewModel.randomPick == nil:
                RandomMangaCardView(
                    pick: nil,
                    isDrawing: false,
                    errorMessage: error,
                    cooldownText: nil,
                    drawButtonTitle: viewModel.drawButtonTitle,
                    canDraw: viewModel.canDraw,
                    detailMalId: viewModel.randomPick?.malId,
                    onDrawTap: viewModel.drawRandomManga
                )
            case .loading:
                RandomMangaCardView(
                    pick: viewModel.randomPick,
                    isDrawing: true,
                    cooldownText: nil,
                    drawButtonTitle: viewModel.drawButtonTitle,
                    canDraw: viewModel.canDraw,
                    detailMalId: viewModel.randomPick?.malId,
                    onDrawTap: viewModel.drawRandomManga
                )
            case .ready, .cooldown:
                RandomMangaCardView(
                    pick: viewModel.randomPick,
                    isDrawing: false,
                    cooldownText: viewModel.cooldownRemainingSeconds > 0 ? "再次抽選倒數 \(viewModel.cooldownDisplayText)" : nil,
                    drawButtonTitle: viewModel.drawButtonTitle,
                    canDraw: viewModel.canDraw,
                    detailMalId: viewModel.randomPick?.malId,
                    onDrawTap: viewModel.drawRandomManga
                )
            case .failure:
                RandomMangaCardView(
                    pick: viewModel.randomPick,
                    isDrawing: false,
                    cooldownText: nil,
                    drawButtonTitle: viewModel.drawButtonTitle,
                    canDraw: viewModel.canDraw,
                    detailMalId: viewModel.randomPick?.malId,
                    onDrawTap: viewModel.drawRandomManga
                )
            }
        }
    }
}

private struct RandomMangaCardView: View {
    let pick: MangaListRandomDTO?
    let isDrawing: Bool
    var errorMessage: String? = nil
    var cooldownText: String? = nil
    let drawButtonTitle: String
    let canDraw: Bool
    let detailMalId: Int?
    let onDrawTap: () -> Void

    private static let heroHeight: CGFloat = 370
    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                heroBackground
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.18),
                        Color.black.opacity(0.74)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 12) {
                    heroBadge
                        .padding(.trailing, 48)

                    Spacer(minLength: 0)

                    HStack(alignment: .bottom, spacing: 14) {
                        posterPanel(width: posterWidth(for: proxy.size.width))

                        VStack(alignment: .leading, spacing: 8) {
                            heroHeadline
                            heroMetadata
                            heroSynopsis

                            if let cooldownText, !cooldownText.isEmpty {
                                Text(cooldownText)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.86))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                    }

                    RandomMangaActionButtonsView(
                        drawButtonTitle: drawButtonTitle,
                        canDraw: canDraw,
                        detailMalId: detailMalId,
                        onDrawTap: onDrawTap
                    )
                }
                .padding(.horizontal, Self.horizontalPadding)
                .padding(.vertical, Self.verticalPadding)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(maxWidth: .infinity)
        .frame(height: Self.heroHeight)
        .overlay(alignment: .topTrailing) {
            if let malId = pick?.id {
                MyListCollectionStatusBadgeView(malId: malId, mediaKind: .manga)
                    .padding(12)
            }
        }
        .overlay {
            if isDrawing {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)

                VStack(spacing: 10) {
                    ProgressView()
                        .tint(ThemeColor.sakura)

                    Text("正在幫你抽選下一部作品…")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(ThemeColor.textPrimary)
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08))
        }
    }

    private func posterWidth(for containerWidth: CGFloat) -> CGFloat {
        min(118, max(92, containerWidth * 0.32))
    }

    @ViewBuilder
    private var heroBackground: some View {
        if let url = pick?.posterURL {
            WebImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(.secondarySystemFill)
            }
            .blur(radius: 18)
            .scaleEffect(1.08)
            .overlay(Color.black.opacity(0.18))
        } else {
            LinearGradient(
                colors: [
                    ThemeColor.sakura.opacity(0.45),
                    Color(.secondarySystemFill)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.38))
            }
        }
    }

    private var heroBadge: some View {
        Text(pick == nil ? "隨機推薦" : "MANGA RANDOM PICK")
            .font(.caption.weight(.black))
            .kerning(0.8)
            .foregroundStyle(ThemeColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(ThemeColor.sakura.opacity(0.84))
            .clipShape(Capsule())
    }

    private func posterPanel(width: CGFloat) -> some View {
        Group {
            if let url = pick?.posterURL {
                WebImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Color(.systemBackground)
                }
                .frame(width: width, height: width * 1.48)
            } else {
                Color(.secondarySystemFill)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: width, height: width * 1.48)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14))
        }
        .shadow(color: Color.black.opacity(0.22), radius: 18, y: 10)
    }

    private var heroHeadline: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let pick {
                Text(pick.displayTitle)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
                    .multilineTextAlignment(.leading)
            } else {
                Text("載入失敗")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                        .lineLimit(2)
                }
            }
        }
    }

    private var heroMetadata: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                metadataChips
            }

            HStack(spacing: 8) {
                if let type = pick?.type, !type.isEmpty {
                    chip(text: type)
                }
                if let score = pick?.score {
                    chip(text: String(format: "★ %.1f", score))
                }
            }
        }
    }

    @ViewBuilder
    private var metadataChips: some View {
        if let type = pick?.type, !type.isEmpty {
            chip(text: type)
        }
        if let score = pick?.score {
            chip(text: String(format: "★ %.1f", score))
        }
        if let chapters = pick?.chapters {
            chip(text: "\(chapters) 話")
        } else if let volumes = pick?.volumes {
            chip(text: "\(volumes) 卷")
        }
    }

    private var shouldShowSynopsis: Bool {
        switch (pick?.synopsisPreview, errorMessage) {
        case (.some, nil):
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private var heroSynopsis: some View {
        if shouldShowSynopsis, let synopsis = pick?.synopsisPreview {
            Text(synopsis)
                .font(.footnote)
                .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }

    private func chip(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.16))
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
                    HStack(spacing: 6) {
                        Text("查看詳情")
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
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
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(height: 370)
    }
}

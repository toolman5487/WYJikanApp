//
//  RandomPickHeroCardView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI
import SDWebImageSwiftUI

enum RandomPickHeroLayout {
    static let heroHeight: CGFloat = 320
    static let cardCornerRadius: CGFloat = 20
    static let posterCornerRadius: CGFloat = 16
    static let actionButtonMinHeight: CGFloat = 44
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 16
}

struct RandomPickHeroCardView<DetailDestination: View>: View {

    // MARK: - Properties

    let item: RandomPickHeroItem?
    let style: RandomPickHeroStyle
    let isDrawing: Bool
    var loadFailure: FeatureLoadFailure? = nil
    let drawButtonTitle: String
    let canDraw: Bool
    let detailID: Int?
    let isFavorite: Bool
    let onDrawTap: () -> Void
    let detailDestination: (Int) -> DetailDestination

    // MARK: - Body

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: RandomPickHeroLayout.heroHeight)
            .overlay {
                GeometryReader { proxy in
                    heroCardBody(containerWidth: proxy.size.width)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: RandomPickHeroLayout.cardCornerRadius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if item != nil {
                    MyListCollectionStatusBadgeView(isFavorite: isFavorite)
                        .padding(12)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if isDrawing {
                    Group {
                        RoundedRectangle(cornerRadius: RandomPickHeroLayout.cardCornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)

                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(ThemeColor.sakura)

                            Text(style.drawingText)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(ThemeColor.textPrimary)
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: RandomPickHeroLayout.cardCornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08))
                    .allowsHitTesting(false)
            }
    }

    // MARK: - Private Methods

    private func heroCardBody(containerWidth: CGFloat) -> some View {
        let resolvedWidth = max(containerWidth, 1)
        let resolvedHeight = RandomPickHeroLayout.heroHeight

        return ZStack {
            heroBackground
                .frame(width: resolvedWidth, height: resolvedHeight)
                .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.74)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 12) {
                heroBadge
                    .padding(.trailing, 48)

                Spacer(minLength: 0)

                HStack(alignment: .bottom, spacing: 16) {
                    posterPanel(width: posterWidth(for: resolvedWidth))

                    VStack(alignment: .leading, spacing: 8) {
                        heroHeadline
                        heroMetadata
                        heroSynopsis
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                }

                actionButtons
            }
            .padding(.horizontal, RandomPickHeroLayout.horizontalPadding)
            .padding(.vertical, RandomPickHeroLayout.verticalPadding)
        }
    }

    private func posterWidth(for containerWidth: CGFloat) -> CGFloat {
        min(118, max(92, containerWidth * 0.32))
    }

    @ViewBuilder
    private var heroBackground: some View {
        if let url = item?.posterURL {
            WebImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(.secondarySystemFill)
            }
            .frame(
                minWidth: 1,
                minHeight: RandomPickHeroLayout.heroHeight
            )
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
                Image(systemName: style.emptySystemImageName)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.38))
            }
        }
    }

    private var heroBadge: some View {
        Text(item == nil ? style.emptyBadgeText : style.readyBadgeText)
            .font(.caption.weight(.black))
            .foregroundStyle(ThemeColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ThemeColor.sakura.opacity(0.84))
            .clipShape(Capsule())
    }

    private func posterPanel(width: CGFloat) -> some View {
        Group {
            if let url = item?.posterURL {
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
        .clipShape(RoundedRectangle(cornerRadius: RandomPickHeroLayout.posterCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RandomPickHeroLayout.posterCornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14))
        }
        .shadow(color: Color.black.opacity(0.22), radius: 18, y: 10)
    }

    private var heroHeadline: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let item {
                Text(item.displayTitle)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
                    .multilineTextAlignment(.leading)
            } else if let loadFailure {
                ErrorMessageView(state: ErrorMessageView.State(failure: loadFailure))
                    .colorScheme(.dark)
            } else {
                Text(style.emptyTitle)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)

                Text(style.emptyDescription)
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                    .lineLimit(2)
            }
        }
    }

    private var heroMetadata: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                metadataChips(from: item?.metadataTexts ?? [])
            }

            HStack(spacing: 8) {
                metadataChips(from: Array((item?.metadataTexts ?? []).prefix(2)))
            }
        }
    }

    @ViewBuilder
    private func metadataChips(from texts: [String]) -> some View {
        ForEach(texts, id: \.self) { text in
            chip(text: text)
        }
    }

    @ViewBuilder
    private var heroSynopsis: some View {
        if loadFailure == nil, let synopsis = item?.synopsisPreview {
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

    @ViewBuilder
    private var actionButtons: some View {
        if let id = detailID {
            HStack(spacing: 12) {
                drawButton

                NavigationLink {
                    detailDestination(id)
                } label: {
                    HStack(spacing: 8) {
                        Text("查看詳情")
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: RandomPickHeroLayout.actionButtonMinHeight)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: RandomPickHeroLayout.cardCornerRadius))
                .tint(ThemeColor.sakura)
            }
        } else {
            drawButton
                .frame(maxWidth: .infinity)
        }
    }

    private var drawButton: some View {
        Button(action: onDrawTap) {
            Text(drawButtonTitle)
                .frame(maxWidth: .infinity, minHeight: RandomPickHeroLayout.actionButtonMinHeight)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: RandomPickHeroLayout.cardCornerRadius))
        .tint(ThemeColor.sakura)
        .disabled(!canDraw)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        RandomPickHeroCardView(
            item: RandomPickHeroItem(
                id: 1,
                displayTitle: "とても長いタイトルのサンプル作品",
                posterURL: nil,
                metadataTexts: ["TV", "★ 8.5", "12 話"],
                synopsisPreview: "這是一段用來預覽 Random Hero 版型的示意介紹文字，讓卡片看起來更接近實際內容。"
            ),
            style: RandomPickHeroStyle(
                emptyBadgeText: "隨機推薦",
                readyBadgeText: "RANDOM PICK",
                emptySystemImageName: "sparkles.tv",
                emptyTitle: "今天抽這部",
                emptyDescription: "按下按鈕，交給系統幫你抽出下一部值得開看的作品。",
                drawingText: "正在幫你抽選下一部作品..."
            ),
            isDrawing: false,
            drawButtonTitle: "00:08 後可再抽",
            canDraw: false,
            detailID: 1,
            isFavorite: true,
            onDrawTap: {},
            detailDestination: { _ in EmptyView() }
        )
        .frame(width: 344)
    }
    .padding()
}

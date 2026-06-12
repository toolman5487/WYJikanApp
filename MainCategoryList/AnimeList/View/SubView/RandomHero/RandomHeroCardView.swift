//
//  RandomHeroCardView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation
import SwiftUI

struct RandomHeroCardView: View {

    // MARK: - Style

    private static let style = RandomPickHeroStyle(
        emptyBadgeText: "隨機推薦",
        readyBadgeText: "ANIME RANDOM PICK",
        emptySystemImageName: "sparkles.tv",
        emptyTitle: "今天抽這部",
        emptyDescription: "按下按鈕，交給系統幫你抽出下一部值得開看的作品。",
        drawingText: "正在幫你抽選下一部作品..."
    )

    // MARK: - Properties

    let pick: AnimeListRandomDTO?
    let isDrawing: Bool
    var loadFailure: FeatureLoadFailure? = nil
    var cooldownText: String? = nil
    let drawButtonTitle: String
    let canDraw: Bool
    let detailMalId: Int?
    let isFavorite: Bool
    let onDrawTap: () -> Void

    // MARK: - Body

    var body: some View {
        RandomPickHeroCardView(
            item: pick.map(RandomPickHeroItem.init(anime:)),
            style: Self.style,
            isDrawing: isDrawing,
            loadFailure: loadFailure,
            cooldownText: cooldownText,
            drawButtonTitle: drawButtonTitle,
            canDraw: canDraw,
            detailID: detailMalId,
            isFavorite: isFavorite,
            onDrawTap: onDrawTap,
            detailDestination: { AnimeDetailView(malId: $0) }
        )
    }
}

// MARK: - RandomPickHeroItem

private extension RandomPickHeroItem {
    init(anime: AnimeListRandomDTO) {
        self.init(
            id: anime.id,
            displayTitle: anime.displayTitle,
            posterURL: anime.posterURL,
            metadataTexts: Self.metadataTexts(from: anime),
            synopsisPreview: anime.synopsisPreview
        )
    }

    static func metadataTexts(from anime: AnimeListRandomDTO) -> [String] {
        var texts: [String] = []

        if let type = anime.type, !type.isEmpty {
            texts.append(type)
        }
        if let score = anime.score {
            texts.append(String(format: "★ %.1f", score))
        }
        if let episodes = anime.episodes {
            texts.append("\(episodes) 話")
        }

        return texts
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        RandomHeroCardView(
            pick: AnimeListRandomDTO(
                malId: 1,
                title: "A Very Very Long Anime Title That Should Still Fit",
                titleEnglish: nil,
                titleJapanese: "とても長いタイトルのサンプルアニメーション",
                synopsis: "這是一段用來預覽 Random Hero 版型的示意介紹文字，讓卡片看起來更接近實際內容。",
                type: "TV",
                score: 8.5,
                rank: nil,
                popularity: nil,
                members: nil,
                episodes: 12,
                images: nil,
                genres: nil
            ),
            isDrawing: false,
            cooldownText: "再次抽選倒數 00:08",
            drawButtonTitle: "再抽一次",
            canDraw: true,
            detailMalId: 1,
            isFavorite: true,
            onDrawTap: {}
        )
        .frame(width: 344)

        RandomHeroCardView(
            pick: nil,
            isDrawing: false,
            loadFailure: FeatureLoadFailure(message: "網路連線不穩，請稍後再試。", kind: .network),
            drawButtonTitle: "開始抽獎",
            canDraw: true,
            detailMalId: nil,
            isFavorite: false,
            onDrawTap: {}
        )
        .frame(width: 344)
    }
    .padding()
}

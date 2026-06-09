//
//  RandomMangaViews.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import Foundation
import SwiftUI

// MARK: - RandomMangaSectionView

struct RandomMangaSectionView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: RandomMangaViewModel
    let favoriteIDs: Set<Int>

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            drawStateContent
        }
    }

    // MARK: - Private Methods

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("今天抽這部")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.sakura)

            Text("試試手氣，隨機挖到下一部想追的漫畫作品。")
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    @ViewBuilder
    private var drawStateContent: some View {
        switch viewModel.drawState {
        case .idle:
            RandomMangaCardView(
                pick: nil,
                isDrawing: false,
                errorMessage: nil,
                cooldownText: nil,
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: nil,
                isFavorite: false,
                onDrawTap: viewModel.drawRandomManga
            )
        case .loading where viewModel.randomPick == nil:
            RandomMangaSkeletonView()

        case .loading:
            RandomMangaCardView(
                pick: viewModel.randomPick,
                isDrawing: true,
                cooldownText: nil,
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: viewModel.randomPick?.malId,
                isFavorite: viewModel.randomPick.map { favoriteIDs.contains($0.id) } ?? false,
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
                isFavorite: viewModel.randomPick.map { favoriteIDs.contains($0.id) } ?? false,
                onDrawTap: viewModel.drawRandomManga
            )

        case .failure:
            RandomMangaCardView(
                pick: viewModel.randomPick,
                isDrawing: false,
                errorMessage: viewModel.drawError,
                cooldownText: nil,
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: viewModel.randomPick?.malId,
                isFavorite: viewModel.randomPick.map { favoriteIDs.contains($0.id) } ?? false,
                onDrawTap: viewModel.drawRandomManga
            )
        }
    }
}

// MARK: - RandomMangaCardView

private struct RandomMangaCardView: View {

    // MARK: - Style

    private static let style = RandomPickHeroStyle(
        emptyBadgeText: "隨機推薦",
        readyBadgeText: "MANGA RANDOM PICK",
        emptySystemImageName: "books.vertical.fill",
        emptyTitle: "今天抽這部",
        emptyDescription: "按下按鈕，交給系統幫你抽出下一部值得開追的漫畫作品。",
        drawingText: "正在幫你抽選下一部作品..."
    )

    // MARK: - Properties

    let pick: MangaListRandomDTO?
    let isDrawing: Bool
    var errorMessage: String? = nil
    var cooldownText: String? = nil
    let drawButtonTitle: String
    let canDraw: Bool
    let detailMalId: Int?
    let isFavorite: Bool
    let onDrawTap: () -> Void

    // MARK: - Body

    var body: some View {
        RandomPickHeroCardView(
            item: pick.map(RandomPickHeroItem.init(manga:)),
            style: Self.style,
            isDrawing: isDrawing,
            errorMessage: errorMessage,
            cooldownText: cooldownText,
            drawButtonTitle: drawButtonTitle,
            canDraw: canDraw,
            detailID: detailMalId,
            isFavorite: isFavorite,
            onDrawTap: onDrawTap,
            detailDestination: { MangaDetailView(malId: $0) }
        )
    }
}

// MARK: - RandomMangaSkeletonView

private struct RandomMangaSkeletonView: View {

    // MARK: - Body

    var body: some View {
        RandomPickHeroSkeletonView(height: 368)
    }
}

// MARK: - RandomPickHeroItem

private extension RandomPickHeroItem {
    init(manga: MangaListRandomDTO) {
        self.init(
            id: manga.id,
            displayTitle: manga.displayTitle,
            posterURL: manga.posterURL,
            metadataTexts: Self.metadataTexts(from: manga),
            synopsisPreview: manga.synopsisPreview
        )
    }

    static func metadataTexts(from manga: MangaListRandomDTO) -> [String] {
        var texts: [String] = []

        if let type = manga.type, !type.isEmpty {
            texts.append(type)
        }
        if let score = manga.score {
            texts.append(String(format: "★ %.1f", score))
        }
        if let chapters = manga.chapters {
            texts.append("\(chapters) 話")
        } else if let volumes = manga.volumes {
            texts.append("\(volumes) 卷")
        }

        return texts
    }
}

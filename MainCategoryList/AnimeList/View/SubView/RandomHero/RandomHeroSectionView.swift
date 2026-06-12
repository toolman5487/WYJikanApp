//
//  RandomHeroSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct RandomHeroSectionView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: RandomHeroViewModel
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

            Text("不知道看什麼？試試手氣，隨機挖到下一部想追的作品。")
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    @ViewBuilder
    private var drawStateContent: some View {
        switch viewModel.drawState {
        case .idle:
            RandomHeroCardView(
                pick: nil,
                isDrawing: false,
                loadFailure: nil,
                cooldownText: nil,
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: nil,
                isFavorite: false,
                onDrawTap: viewModel.drawRandomAnime
            )
        case .loading where viewModel.randomPick == nil:
            RandomHeroSkeletonView()

        case .loading:
            RandomHeroCardView(
                pick: viewModel.randomPick,
                isDrawing: true,
                cooldownText: nil,
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: viewModel.randomPick?.malId,
                isFavorite: viewModel.randomPick.map { favoriteIDs.contains($0.id) } ?? false,
                onDrawTap: viewModel.drawRandomAnime
            )

        case .ready, .cooldown:
            RandomHeroCardView(
                pick: viewModel.randomPick,
                isDrawing: false,
                cooldownText: viewModel.cooldownRemainingSeconds > 0 ? "再次抽選倒數 \(viewModel.cooldownDisplayText)" : nil,
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: viewModel.randomPick?.malId,
                isFavorite: viewModel.randomPick.map { favoriteIDs.contains($0.id) } ?? false,
                onDrawTap: viewModel.drawRandomAnime
            )

        case .failure:
            RandomHeroCardView(
                pick: viewModel.randomPick,
                isDrawing: false,
                loadFailure: viewModel.drawFailure,
                cooldownText: nil,
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: viewModel.randomPick?.malId,
                isFavorite: viewModel.randomPick.map { favoriteIDs.contains($0.id) } ?? false,
                onDrawTap: viewModel.drawRandomAnime
            )
        }
    }
}

// MARK: - Preview

#Preview {
    RandomHeroSectionView(
        viewModel: RandomHeroViewModel(service: AppDependencies.live.mainCategoryListService),
        favoriteIDs: []
    )
}

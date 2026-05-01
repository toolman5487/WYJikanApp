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

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今天抽這部")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ThemeColor.sakura)

                Text("不知道看什麼？試試手氣，隨機挖到下一部想追的作品。")
                    .font(.subheadline)
                    .foregroundStyle(ThemeColor.textSecondary)
            }

            switch viewModel.drawState {
            case .loading where viewModel.randomPick == nil:
                RandomHeroSkeletonView()
            case .failure(let error) where viewModel.randomPick == nil:
                RandomHeroCardView(
                    pick: nil,
                    isDrawing: false,
                    errorMessage: error,
                    cooldownText: nil
                )
            case .loading:
                RandomHeroCardView(
                    pick: viewModel.randomPick,
                    isDrawing: true,
                    cooldownText: nil
                )
            case .ready, .cooldown:
                RandomHeroCardView(
                    pick: viewModel.randomPick,
                    isDrawing: false,
                    cooldownText: viewModel.cooldownRemainingSeconds > 0 ? "再次抽選倒數 \(viewModel.cooldownDisplayText)" : nil
                )
            case .failure:
                RandomHeroCardView(
                    pick: viewModel.randomPick,
                    isDrawing: false,
                    cooldownText: nil
                )
            }

            RandomHeroActionButtonsView(
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: viewModel.randomPick?.malId,
                onDrawTap: viewModel.drawRandomAnime
            )
        }
    }
}

#Preview {
    RandomHeroSectionView(
        viewModel: RandomHeroViewModel()
    )
}

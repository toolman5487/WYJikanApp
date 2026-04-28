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
            switch viewModel.drawState {
            case .loading where viewModel.randomPick == nil:
                RandomHeroSkeletonView()
            case .failure(let error) where viewModel.randomPick == nil:
                RandomHeroCardView(
                    pick: nil,
                    isDrawing: false,
                    errorMessage: error
                )
            case .loading:
                RandomHeroCardView(
                    pick: viewModel.randomPick,
                    isDrawing: true
                )
            case .ready, .cooldown:
                RandomHeroCardView(
                    pick: viewModel.randomPick,
                    isDrawing: false
                )
            case .failure:
                RandomHeroCardView(
                    pick: viewModel.randomPick,
                    isDrawing: false
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

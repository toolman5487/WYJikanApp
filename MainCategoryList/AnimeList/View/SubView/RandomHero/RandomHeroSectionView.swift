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
            case .loading(let pick) where pick == nil:
                RandomHeroSkeletonView()
            case .failure(let error, let pick) where pick == nil:
                RandomHeroCardView(
                    pick: nil,
                    isDrawing: false,
                    errorMessage: error
                )
            case .loading(let pick):
                RandomHeroCardView(
                    pick: pick,
                    isDrawing: true
                )
            case .ready(let pick):
                RandomHeroCardView(
                    pick: pick,
                    isDrawing: false
                )
            case .failure(_, let pick):
                RandomHeroCardView(
                    pick: pick,
                    isDrawing: false
                )
            case .cooldown(let pick, _):
                RandomHeroCardView(
                    pick: pick,
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

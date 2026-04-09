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
        let pick = viewModel.randomPick
        let isDrawing = viewModel.isDrawing
        let drawError = viewModel.drawError

        VStack(alignment: .leading, spacing: 12) {
            Group {
                if isDrawing, pick == nil {
                    RandomHeroSkeletonView()
                } else if let error = drawError, pick == nil {
                    RandomHeroCardView(
                        pick: nil,
                        isDrawing: false,
                        errorMessage: error
                    )
                } else {
                    RandomHeroCardView(
                        pick: pick,
                        isDrawing: isDrawing
                    )
                }
            }

            RandomHeroActionButtonsView(
                drawButtonTitle: viewModel.drawButtonTitle,
                canDraw: viewModel.canDraw,
                detailMalId: pick?.malId,
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

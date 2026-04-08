//
//  RandomHeroSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct RandomHeroSectionView: View {
    let randomPick: AnimeListRandomDTO?
    let isDrawing: Bool
    let drawError: String?
    let onDrawTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if isDrawing, randomPick == nil {
                    RandomHeroSkeletonView()
                } else if let error = drawError, randomPick == nil {
                    RandomHeroCardView(
                        pick: nil,
                        isDrawing: false,
                        errorMessage: error
                    )
                } else {
                    RandomHeroCardView(
                        pick: randomPick,
                        isDrawing: isDrawing
                    )
                }
            }

            RandomHeroActionButtonsView(
                isDrawing: isDrawing,
                detailMalId: randomPick?.malId,
                onDrawTap: onDrawTap
            )
        }
    }
}

#Preview {
    RandomHeroSectionView(
        randomPick: nil,
        isDrawing: true,
        drawError: nil,
        onDrawTap: {}
    )
}

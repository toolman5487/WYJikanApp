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
    let cooldownRemainingSeconds: Int
    let cooldownDisplayText: String
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
                cooldownRemainingSeconds: cooldownRemainingSeconds,
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
        cooldownRemainingSeconds: 0,
        cooldownDisplayText: "00:00",
        onDrawTap: {}
    )
}

//
//  RandomHeroActionButtonsView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct RandomHeroActionButtonsView: View {
    let isDrawing: Bool
    let cooldownRemainingSeconds: Int
    let detailMalId: Int?
    let onDrawTap: () -> Void

    private var canDraw: Bool {
        !isDrawing && cooldownRemainingSeconds == 0
    }

    private var drawButtonTitle: String {
        if cooldownRemainingSeconds == 0 {
            return "再抽一次"
        }
        let minutes = cooldownRemainingSeconds / 60
        let seconds = cooldownRemainingSeconds % 60
        return String(format: "%02d:%02d 後可再抽", minutes, seconds)
    }

    var body: some View {
        if let id = detailMalId {
            HStack(spacing: 12) {
                Button(action: onDrawTap) {
                    Text(drawButtonTitle)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
                .disabled(!canDraw)

                NavigationLink {
                    AnimeDetailView(malId: id)
                } label: {
                    Text("查看詳情")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
            }
        } else {
            Button(action: onDrawTap) {
                Text(drawButtonTitle)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColor.sakura)
            .disabled(!canDraw)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    RandomHeroActionButtonsView(
        isDrawing: false,
        cooldownRemainingSeconds: 0,
        detailMalId: 1,
        onDrawTap: {}
    )
}

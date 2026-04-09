//
//  RandomHeroActionButtonsView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct RandomHeroActionButtonsView: View {
    // MARK: - Properties

    let drawButtonTitle: String
    let canDraw: Bool
    let detailMalId: Int?
    let onDrawTap: () -> Void

    // MARK: - View

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
        drawButtonTitle: "再抽一次",
        canDraw: true,
        detailMalId: 1,
        onDrawTap: {}
    )
}

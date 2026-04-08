//
//  RandomHeroActionButtonsView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct RandomHeroActionButtonsView: View {
    let isDrawing: Bool
    let detailMalId: Int?
    let onDrawTap: () -> Void

    var body: some View {
        if let id = detailMalId {
            HStack(spacing: 12) {
                Button(action: onDrawTap) {
                    Text("再抽一次")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
                .disabled(isDrawing)

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
                Text("再抽一次")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColor.sakura)
            .disabled(isDrawing)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    RandomHeroActionButtonsView(
        isDrawing: false,
        detailMalId: 1,
        onDrawTap: {}
    )
}

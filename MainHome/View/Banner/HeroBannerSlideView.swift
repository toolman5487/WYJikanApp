//
//  HeroBannerSlideView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct HeroBannerSlideView: View {
    let item: BannerItem
    let pageLabel: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HeroBannerImageView(url: item.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(alignment: .center) {
                Text("本季焦點")
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(ThemeColor.sakura.opacity(0.95))
                    .clipShape(Capsule())

                Spacer(minLength: 12)

                Text(pageLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.ultraThinMaterial.opacity(0.55))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

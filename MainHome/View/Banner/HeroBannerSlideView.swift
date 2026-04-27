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
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("本季焦點")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(ThemeColor.sakura.opacity(0.95))
                            .clipShape(Capsule())

                        if let type = item.type, !type.isEmpty {
                            badge(text: type)
                        }

                        if let score = item.score {
                            badge(text: String(format: "★ %.2f", score))
                        }

                        Spacer(minLength: 12)

                        Text(pageLabel)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(.ultraThinMaterial.opacity(0.55))
                            .clipShape(Capsule())
                    }

                    Text(item.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func badge(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial.opacity(0.55))
            .clipShape(Capsule())
    }
}

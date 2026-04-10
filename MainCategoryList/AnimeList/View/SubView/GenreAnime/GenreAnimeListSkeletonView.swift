//
//  GenreAnimeListSkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import SwiftUI

struct GenreAnimeListSkeletonView: View {
    // MARK: - Constants

    private static let cardCount: Int = 6
    private static let cardHeight: CGFloat = 240
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0
    private static let cardCornerRadius: CGFloat = 16
    private static let cardSpacing: CGFloat = 12
    private static let horizontalPadding: CGFloat = 16
    private static let sectionCount: Int = 3

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(0..<Self.sectionCount, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    SkeletonBar(width: 120, height: 24, cornerRadius: 8)
                        .padding(.horizontal, Self.horizontalPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Self.cardSpacing) {
                            ForEach(0..<Self.cardCount, id: \.self) { _ in
                                RoundedRectangle(
                                    cornerRadius: Self.cardCornerRadius,
                                    style: .continuous
                                )
                                .fill(Color(.systemGray5))
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: Self.cardCornerRadius,
                                        style: .continuous
                                    )
                                )
                                .frame(
                                    width: Self.cardHeight * Self.posterAspectRatio,
                                    height: Self.cardHeight
                                )
                            }
                        }
                        .padding(.horizontal, Self.horizontalPadding)
                    }
                }
            }
        }
    }
}

#Preview {
    GenreAnimeListSkeletonView()
}

//
//  TrendingMangaView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct HomeTrendingMangaView: View {
    @StateObject private var viewModel = HomeTrendingMangaViewModel()

    private static let cardWidth: CGFloat = 160
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0
    private static let cardCornerRadius: CGFloat = 16
    private static let cardSpacing: CGFloat = 16
    private static let horizontalPadding: CGFloat = 16
    private static let skeletonCount: Int = 10

    private static var cardHeight: CGFloat {
        cardWidth / Self.posterAspectRatio
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("熱門排行")
                .font(.title3.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.cardSpacing) {
                    if viewModel.isLoading {
                        ForEach(0..<Self.skeletonCount, id: \.self) { _ in
                            BannerSkeletonView()
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: Self.cardCornerRadius,
                                        style: .continuous
                                    )
                                )
                                .frame(width: Self.cardWidth, height: Self.cardHeight)
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorMessageView(message: errorMessage, height: Self.cardHeight)
                            .frame(width: Self.cardWidth)
                    } else if viewModel.items.isEmpty {
                        ErrorMessageView(message: "Empty Data", height: Self.cardHeight)
                            .frame(width: Self.cardWidth)
                    } else {
                        ForEach(viewModel.items) { item in
                            TrendingMangaCardView(item: item)
                                .frame(width: Self.cardWidth, height: Self.cardHeight)
                        }
                    }
                }
                .padding(.horizontal, Self.horizontalPadding)
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}

#Preview {
    HomeTrendingMangaView()
}

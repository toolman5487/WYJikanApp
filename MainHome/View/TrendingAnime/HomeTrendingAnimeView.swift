//
//  HomeTrendingView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct HomeTrendingAnimeView: View {
    @StateObject private var viewModel = HomeTrendingAnimeViewModel()
    @EnvironmentObject private var router: MainHomeRouter
    
    private static let cardHeight: CGFloat = 240
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0
    private static let cardCornerRadius: CGFloat = 16
    private static let cardSpacing: CGFloat = 16
    private static let horizontalPadding: CGFloat = 16
    private static let skeletonCount: Int = 10
    private static var cardWidth: CGFloat {
        cardHeight * Self.posterAspectRatio
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("熱門動畫")
                .padding()
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.sakura)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.cardSpacing) {
                    if viewModel.isLoading {
                        ForEach(0..<Self.skeletonCount, id: \.self) { _ in
                            BannerSkeletonView()
                                .clipShape(RoundedRectangle(cornerRadius: Self.cardCornerRadius, style: .continuous))
                                .frame(width: Self.cardWidth, height: Self.cardHeight)
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorMessageView(message: errorMessage, height: Self.cardHeight)
                            .frame(width: Self.cardWidth)
                    } else if viewModel.items.isEmpty {
                        ErrorMessageView(message: "尚無資料，稍後嘗試", height: Self.cardHeight)
                            .frame(width: Self.cardWidth)
                    } else {
                        ForEach(viewModel.items) { item in
                            Button {
                                router.push(.animeDetail(malId: item.id))
                            } label: {
                                PosterCardView(rank: item.rank) {
                                    RemotePosterImageView(url: item.imageURL)
                                }
                                .frame(width: Self.cardWidth, height: Self.cardHeight)
                            }
                            .buttonStyle(.plain)
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
    HomeTrendingAnimeView()
        .environmentObject(MainHomeRouter())
}

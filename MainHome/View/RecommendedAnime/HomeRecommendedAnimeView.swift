//
//  HomeRecommendedAnimeView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/27.
//

import SwiftUI

struct HomeRecommendedAnimeView: View {
    @StateObject private var viewModel = HomeRecommendedAnimeViewModel()
    @EnvironmentObject private var router: MainHomeRouter

    private static let posterHeight: CGFloat = 240
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0
    private static let cardSpacing: CGFloat = 16
    private static let horizontalPadding: CGFloat = 16
    private static let skeletonCount: Int = 6

    private static var cardWidth: CGFloat {
        posterHeight * posterAspectRatio
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("推薦作品")
                .padding()
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.sakura)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.cardSpacing) {
                    switch viewModel.viewState {
                    case .loading:
                        ForEach(0..<Self.skeletonCount, id: \.self) { _ in
                            BannerSkeletonView()
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .frame(width: Self.cardWidth, height: Self.posterHeight)
                        }
                    case .failed(let errorMessage):
                        ErrorMessageView(message: errorMessage, height: Self.posterHeight)
                            .frame(width: Self.cardWidth)
                    case .empty:
                        ErrorMessageView(message: "尚無推薦資料", height: Self.posterHeight)
                            .frame(width: Self.cardWidth)
                    case .loaded:
                        ForEach(viewModel.items) { item in
                            Button {
                                router.push(.animeDetail(malId: item.detailMalId))
                            } label: {
                                PosterCardView {
                                    RemotePosterImageView(url: item.imageURL)
                                }
                                .frame(width: Self.cardWidth, height: Self.posterHeight)
                                .overlay(alignment: .bottomLeading) {
                                    PosterCardMetadataOverlayView(
                                        title: item.recommendedTitle,
                                        type: item.username.map { "@\($0)" },
                                        score: nil
                                    )
                                }
                                .overlay(alignment: .topTrailing) {
                                    MyListCollectionStatusBadgeView(malId: item.detailMalId, mediaKind: .anime)
                                        .padding(8)
                                }
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
    HomeRecommendedAnimeView()
        .environmentObject(MainHomeRouter())
}

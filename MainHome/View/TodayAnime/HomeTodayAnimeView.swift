//
//  HomeTodayAnimeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct HomeTodayAnimeView: View {
    @StateObject private var viewModel = HomeTodayAnimeViewModel()
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
            Text("當日動畫")
                .padding()
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.sakura)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.cardSpacing) {
                    switch viewModel.screenState {
                    case .loading:
                        ForEach(0..<Self.skeletonCount, id: \.self) { _ in
                            BannerSkeletonView()
                                .clipShape(RoundedRectangle(cornerRadius: Self.cardCornerRadius, style: .continuous))
                                .frame(width: Self.cardWidth, height: Self.cardHeight)
                        }
                    case .error(let errorMessage):
                        ErrorMessageView(message: errorMessage, height: Self.cardHeight)
                            .frame(width: Self.cardWidth)
                    case .empty:
                        ErrorMessageView(message: "Empty Data", height: Self.cardHeight)
                            .frame(width: Self.cardWidth)
                    case .content:
                        ForEach(viewModel.items) { item in
                            Button {
                                router.push(.animeDetail(malId: item.id))
                            } label: {
                                PosterCardView {
                                    RemotePosterImageView(url: item.imageURL)
                                }
                                .frame(width: Self.cardWidth, height: Self.cardHeight)
                                .overlay(alignment: .bottomLeading) {
                                    PosterCardMetadataOverlayView(
                                        title: item.title,
                                        type: item.type,
                                        score: item.score
                                    )
                                }
                                .overlay(alignment: .topTrailing) {
                                    MyListCollectionStatusBadgeView(malId: item.id, mediaKind: .anime)
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
    HomeTodayAnimeView()
        .environmentObject(MainHomeRouter())
}

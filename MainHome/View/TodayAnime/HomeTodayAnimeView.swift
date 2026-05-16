//
//  HomeTodayAnimeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct HomeTodayAnimeView: View {
    @ObservedObject private var viewModel: HomeTodayAnimeViewModel
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @EnvironmentObject private var router: MainHomeRouter
    let showsHeader: Bool
    
    private static let cardHeight: CGFloat = 240
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0
    private static let cardCornerRadius: CGFloat = 16
    private static let cardSpacing: CGFloat = 16
    private static let horizontalPadding: CGFloat = 16
    private static let skeletonCount: Int = 10
    
    private static var cardWidth: CGFloat {
        cardHeight * Self.posterAspectRatio
    }

    init(
        viewModel: HomeTodayAnimeViewModel,
        showsHeader: Bool = true
    ) {
        self.viewModel = viewModel
        self.showsHeader = showsHeader
    }
    
    var body: some View {
        let favoriteIDs = favoriteStatusStore.favoriteIDs(for: .anime)

        VStack(alignment: .leading, spacing: 0) {
            if showsHeader {
                GlassSectionHeaderView(
                    title: "今日動畫",
                    state: .navigable(action: { router.push(.todayAnimeSchedule) })
                )
            }
            
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
                        ErrorMessageView(state: .network(errorMessage), height: Self.cardHeight)
                            .frame(width: Self.cardWidth)
                    case .empty:
                        ErrorMessageView(state: .emptyCollection("尚無資料"), height: Self.cardHeight)
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
                                    MyListCollectionStatusBadgeView(isFavorite: favoriteIDs.contains(item.id))
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
    }
}

#Preview {
    HomeTodayAnimeView(viewModel: HomeTodayAnimeViewModel())
        .environmentObject(FavoriteStatusStore())
        .environmentObject(MainHomeRouter())
}

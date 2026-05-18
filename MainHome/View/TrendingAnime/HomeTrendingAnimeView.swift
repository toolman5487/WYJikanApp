//
//  HomeTrendingAnimeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct HomeTrendingAnimeView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @ObservedObject private var viewModel: HomeTrendingAnimeViewModel

    let showsHeader: Bool

    private let cardWidth: CGFloat = 240 * (2.0 / 3.0)

    // MARK: - Lifecycle

    init(
        viewModel: HomeTrendingAnimeViewModel,
        showsHeader: Bool = true
    ) {
        self.viewModel = viewModel
        self.showsHeader = showsHeader
    }

    // MARK: - Body

    var body: some View {
        let favoriteIDs = favoriteStatusStore.favoriteIDs(for: .anime)

        VStack(alignment: .leading, spacing: 0) {
            if showsHeader {
                GlassSectionHeaderView(
                    title: "熱門動畫",
                    state: .navigable(action: { router.push(.trendingAnimeList) })
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    switch viewModel.screenState {
                    case .loading:
                        ForEach(0..<10, id: \.self) { _ in
                            BannerSkeletonView()
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .frame(width: cardWidth, height: 240)
                        }

                    case .error(let errorMessage):
                        ErrorMessageView(state: .network(errorMessage), height: 240)
                            .frame(width: cardWidth)

                    case .empty:
                        ErrorMessageView(state: .emptyCollection("尚無資料，稍後嘗試"), height: 240)
                            .frame(width: cardWidth)

                    case .content:
                        ForEach(viewModel.items) { item in
                            Button {
                                router.push(.animeDetail(malId: item.id))
                            } label: {
                                PosterCardView(rank: item.rank) {
                                    RemotePosterImageView(url: item.imageURL)
                                }
                                .frame(width: cardWidth, height: 240)
                                .overlay(alignment: .bottomLeading) {
                                    PosterCardMetadataOverlayView(
                                        title: item.title,
                                        type: item.type,
                                        score: item.score
                                    )
                                }
                                .overlay(alignment: .topTrailing) {
                                    MyListCollectionStatusBadgeView(
                                        isFavorite: favoriteIDs.contains(item.id)
                                    )
                                    .padding(8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }
}

#Preview {
    HomeTrendingAnimeView(viewModel: HomeTrendingAnimeViewModel())
        .environmentObject(FavoriteStatusStore())
        .environmentObject(MainHomeRouter())
}

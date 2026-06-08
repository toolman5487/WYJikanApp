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
    @State private var endBounceProgress: CGFloat = 0

    let showsHeader: Bool

    private let cardSize = MainHomePosterCardMetrics.size

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
                LazyHStack(spacing: 16) {
                    switch viewModel.screenState {
                    case .loading:
                        ForEach(0..<10, id: \.self) { _ in
                            BannerSkeletonView()
                                .clipShape(RoundedRectangle(cornerRadius: MainHomePosterCardMetrics.cornerRadius, style: .continuous))
                                .frame(width: cardSize.width, height: cardSize.height)
                        }

                    case .error(let errorMessage):
                        ErrorMessageView(state: .network(errorMessage), height: cardSize.height)
                            .frame(width: cardSize.width)

                    case .empty:
                        ErrorMessageView(state: .emptyCollection("尚無資料，稍後嘗試"), height: cardSize.height)
                            .frame(width: cardSize.width)

                    case .content:
                        ForEach(viewModel.items) { item in
                            Button {
                                router.push(.animeDetail(malId: item.id))
                            } label: {
                                PosterCardView(rank: item.rank) {
                                    RemotePosterImageView(
                                        url: item.imageURL,
                                        fixedSize: cardSize
                                    )
                                }
                                .frame(width: cardSize.width, height: cardSize.height)
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

                        EndBounceHintView(
                            axis: .horizontal,
                            title: "完整熱門動畫",
                            subtitle: "繼續往右拉查看榜單",
                            progress: endBounceProgress,
                            width: cardSize.width,
                            height: cardSize.height,
                            cornerRadius: MainHomePosterCardMetrics.cornerRadius
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .onEndBounce(
                axis: .horizontal,
                isEnabled: viewModel.screenState.hasContent,
                progress: $endBounceProgress
            ) {
                router.push(.trendingAnimeList)
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

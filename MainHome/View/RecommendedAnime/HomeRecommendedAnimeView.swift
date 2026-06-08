//
//  HomeRecommendedAnimeView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/27.
//

import SwiftUI

struct HomeRecommendedAnimeView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @ObservedObject private var viewModel: HomeRecommendedAnimeViewModel

    let showsHeader: Bool

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16, alignment: .top),
        count: 3
    )

    // MARK: - Lifecycle

    init(
        viewModel: HomeRecommendedAnimeViewModel,
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
                GlassSectionHeaderView(title: "作品推薦")
            }

            VStack(alignment: .leading, spacing: 0) {
                switch viewModel.screenState {
                case .loading:
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                        ForEach(0..<9, id: \.self) { _ in
                            BannerSkeletonView()
                                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 16)

                case .error(let errorMessage):
                    ErrorMessageView(state: .network(errorMessage), height: 240)
                        .padding(.horizontal, 16)

                case .empty:
                    ErrorMessageView(state: .emptyCollection("尚無推薦資料"), height: 240)
                        .padding(.horizontal, 16)

                case .content:
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                        ForEach(viewModel.displayedItems) { item in
                            Button {
                                router.push(.animeDetail(malId: item.detailMalId))
                            } label: {
                                PosterCardView {
                                    RemotePosterImageView(url: item.imageURL)
                                }
                                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                                .overlay(alignment: .bottomLeading) {
                                    PosterCardMetadataOverlayView(
                                        title: "",
                                        type: item.username.map { "@\($0)" },
                                        score: nil
                                    )
                                }
                                .overlay(alignment: .topTrailing) {
                                    MyListCollectionStatusBadgeView(
                                        isFavorite: favoriteIDs.contains(item.detailMalId)
                                    )
                                    .padding(8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }
}

#Preview {
    HomeRecommendedAnimeView(viewModel: HomeRecommendedAnimeViewModel())
        .environmentObject(FavoriteStatusStore())
        .environmentObject(MainHomeRouter())
}

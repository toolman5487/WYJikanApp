//
//  HomeRecommendedAnimeView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/27.
//

import SwiftUI

// MARK: - HomeRecommendedAnimeView

struct HomeRecommendedAnimeView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @ObservedObject private var viewModel: HomeRecommendedAnimeViewModel

    let showsHeader: Bool
    let autoLoadOnAppear: Bool

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    // MARK: - Lifecycle

    init(
        viewModel: HomeRecommendedAnimeViewModel,
        showsHeader: Bool = true,
        autoLoadOnAppear: Bool = true
    ) {
        self.viewModel = viewModel
        self.showsHeader = showsHeader
        self.autoLoadOnAppear = autoLoadOnAppear
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
                            HomeRecommendedAnimeSkeletonCardView()
                        }
                    }
                    .padding(.horizontal, 16)

                case .error(let failure):
                    ErrorMessageView(state: ErrorMessageView.State(failure: failure), height: 240)
                        .padding(.horizontal, 16)

                case .empty:
                    FeatureEmptyStateInlineView(
                        emptyState: .emptyCollection(message: "尚無推薦作品，稍後再試"),
                        height: 240
                    )
                        .padding(.horizontal, 16)

                case .content:
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                        ForEach(viewModel.displayedItems) { item in
                            HomeRecommendedAnimeCardView(
                                item: item,
                                isFavorite: favoriteIDs.contains(item.detailMalId)
                            ) {
                                router.push(.animeDetail(malId: item.detailMalId))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            if autoLoadOnAppear {
                viewModel.loadIfNeeded()
            }
        }
    }
}

private struct HomeRecommendedAnimeCardView: View {

    private static let aspectRatio: CGFloat = 2.0 / 3.0

    let item: HomeRecommendedAnimeCardItem
    let isFavorite: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Rectangle()
                .fill(Color(.systemBackground))
                .aspectRatio(Self.aspectRatio, contentMode: .fit)
                .overlay {
                    GeometryReader { proxy in
                        PosterCardView {
                            RemotePosterImageView(
                                url: item.imageURL,
                                contentMode: .fill,
                                fixedSize: proxy.size
                            )
                        }
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    PosterCardMetadataOverlayView(
                        title: "",
                        type: item.username.map { "@\($0)" },
                        score: nil
                    )
                }
                .overlay(alignment: .topTrailing) {
                    MyListCollectionStatusBadgeView(isFavorite: isFavorite)
                        .padding(8)
                }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct HomeRecommendedAnimeSkeletonCardView: View {

    private static let aspectRatio: CGFloat = 2.0 / 3.0

    var body: some View {
        Rectangle()
            .fill(Color(.systemBackground))
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .overlay {
                BannerSkeletonView()
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: MainHomePosterCardMetrics.cornerRadius,
                            style: .continuous
                        )
                    )
            }
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeRecommendedAnimeView(
        viewModel: HomeRecommendedAnimeViewModel(
            service: AppDependencies.live.mainHomeService,
            animeDetailService: AppDependencies.live.animeDetailService
        )
    )
        .environmentObject(FavoriteStatusStore())
        .environmentObject(MainHomeRouter())
}

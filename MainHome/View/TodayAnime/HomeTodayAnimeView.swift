//
//  HomeTodayAnimeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

// MARK: - HomeTodayAnimeView

struct HomeTodayAnimeView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @ObservedObject private var viewModel: HomeTodayAnimeViewModel
    @State private var endBounceProgress: CGFloat = 0

    let showsHeader: Bool
    let autoLoadOnAppear: Bool

    private let cardSize = MainHomePosterCardMetrics.size

    // MARK: - Lifecycle

    init(
        viewModel: HomeTodayAnimeViewModel,
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
                GlassSectionHeaderView(
                    title: "今日動畫",
                    state: .navigable(action: { router.push(.todayAnimeSchedule) })
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

                    case .error(let failure):
                        ErrorMessageView(state: ErrorMessageView.State(failure: failure), height: cardSize.height)
                            .frame(width: cardSize.width)

                    case .empty:
                        FeatureEmptyStateInlineView(
                            emptyState: .emptyCollection(message: "今天沒有可顯示的動畫"),
                            height: cardSize.height
                        )
                            .frame(width: cardSize.width)

                    case .content:
                        ForEach(viewModel.items) { item in
                            Button {
                                router.push(.animeDetail(malId: item.id))
                            } label: {
                                HomeTodayAnimeCardView(
                                    item: item,
                                    isFavorite: favoriteIDs.contains(item.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        EndBounceHintView(
                            axis: .horizontal,
                            title: "完整今日動畫",
                            subtitle: "繼續往右拉查看時刻表",
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
                router.push(.todayAnimeSchedule)
            }
        }
        .onAppear {
            if autoLoadOnAppear {
                viewModel.loadIfNeeded()
            }
        }
    }
}

private struct HomeTodayAnimeCardView: View {
    let item: HomeTodayAnimeCardItem
    let isFavorite: Bool

    private let cardSize = MainHomePosterCardMetrics.size

    var body: some View {
        PosterCardView {
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
            MyListCollectionStatusBadgeView(isFavorite: isFavorite)
                .padding(8)
        }
    }
}

#Preview {
    HomeTodayAnimeView(viewModel: HomeTodayAnimeViewModel(service: AppDependencies.live.mainHomeService))
        .environmentObject(FavoriteStatusStore())
        .environmentObject(MainHomeRouter())
}

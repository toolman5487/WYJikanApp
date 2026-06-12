//
//  HomeWatchEpisodesView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI

struct HomeWatchEpisodesView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @ObservedObject private var viewModel: HomeWatchEpisodesViewModel
    @State private var endBounceProgress: CGFloat = 0

    let showsHeader: Bool
    let autoLoadOnAppear: Bool

    private let cardSize = MainHomePosterCardMetrics.size

    // MARK: - Lifecycle

    init(
        viewModel: HomeWatchEpisodesViewModel,
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
                GlassSectionHeaderView(title: "新上架集數")
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
                            emptyState: .emptyCollection(message: "尚無可顯示的集數"),
                            height: cardSize.height
                        )
                            .frame(width: cardSize.width)

                    case .content:
                        ForEach(viewModel.items) { item in
                            Button {
                                openEpisode(item)
                            } label: {
                                HomeWatchEpisodeCardView(
                                    item: item,
                                    isFavorite: favoriteIDs.contains(item.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        EndBounceHintView(
                            axis: .horizontal,
                            title: "完整新上架集數",
                            subtitle: "繼續往右拉查看集數列表",
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
                router.push(.watch(feed: .latestEpisodes))
            }
        }
        .onAppear {
            if autoLoadOnAppear {
                viewModel.loadIfNeeded()
            }
        }
    }

    // MARK: - Private Methods

    private func openEpisode(_ item: HomeWatchEpisodeItem) {
        if let episodeURL = item.episodeURL {
            open(.watchEpisode(url: episodeURL))
        } else {
            router.push(.animeDetail(malId: item.id))
        }
    }

    private func open(_ page: BaseWebPage) {
        if page.opensExternally {
            openExternally(page)
        } else {
            router.push(.webPage(page))
        }
    }

    private func openExternally(_ page: BaseWebPage) {
        ExternalURLOpener.open(page.externalURLCandidates)
    }
}

private struct HomeWatchEpisodeCardView: View {
    let item: HomeWatchEpisodeItem
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
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)

                chip(text: item.episodeText)

                if !item.badgeTexts.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(item.badgeTexts.prefix(2), id: \.self) { badge in
                            chip(text: badge)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .overlay(alignment: .topTrailing) {
            MyListCollectionStatusBadgeView(isFavorite: isFavorite)
                .padding(8)
        }
    }

    private func chip(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial.opacity(0.72))
            .clipShape(Capsule())
    }
}

#Preview {
    HomeWatchEpisodesView(viewModel: HomeWatchEpisodesViewModel(service: AppDependencies.live.homeWatchService))
        .environmentObject(FavoriteStatusStore())
        .environmentObject(MainHomeRouter())
}

//
//  ProducerRelatedAnimeSectionView.swift
//  WYJikanApp
//

import SwiftUI

struct ProducerRelatedAnimeSectionView: View {
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore

    let state: ProducerDetailViewModel.RelatedAnimeState
    let producerId: Int
    let producerName: String
    let onRetry: () -> Void

    var body: some View {
        AnimeDetailLinkedSection(
            title: "相關動畫",
            actionTitle: "查看全部"
        ) {
            ProducerAnimeListView(
                producerId: producerId,
                producerName: producerName
            )
        } content: {
            sectionContent
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch state {
        case .loading:
            loadingContent
        case .empty:
            FeatureEmptyStateCardView(
                emptyState: .emptyCollection(
                    title: "目前沒有相關動畫",
                    message: "MyAnimeList 尚未收錄這間公司的動畫作品。"
                )
            )
        case .error(let failure):
            ErrorMessageRetryCardView(
                state: ErrorMessageView.State(failure: failure),
                retryTitle: "重新載入",
                onRetry: onRetry,
                minHeight: 180,
                alignment: .leading
            )
        case .content(let items):
            animeScroll(items)
        }
    }

    private func animeScroll(_ items: [AnimeCategoryItemDTO]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(items) { item in
                    ProducerRelatedAnimeCardView(
                        item: item,
                        isFavorite: favoriteStatusStore
                            .favoriteIDs(for: .anime)
                            .contains(item.id)
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var loadingContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonBar(
                        width: MainHomePosterCardMetrics.width,
                        height: MainHomePosterCardMetrics.height,
                        cornerRadius: MainHomePosterCardMetrics.cornerRadius
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct ProducerRelatedAnimeCardView: View {
    let item: AnimeCategoryItemDTO
    let isFavorite: Bool

    var body: some View {
        NavigationLink {
            AnimeDetailView(malId: item.id)
        } label: {
            PosterCardView(rank: item.rank) {
                poster
            }
            .frame(
                width: MainHomePosterCardMetrics.width,
                height: MainHomePosterCardMetrics.height
            )
            .overlay(alignment: .bottomLeading) {
                PosterCardMetadataOverlayView(
                    title: item.displayTitle,
                    type: MediaTypeFormatting.localizedName(
                        for: item.type,
                        kind: .anime
                    ),
                    score: item.score
                )
            }
            .overlay(alignment: .topTrailing) {
                MyListCollectionStatusBadgeView(isFavorite: isFavorite)
                    .padding(8)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var poster: some View {
        if let posterURL = item.posterURL {
            RemotePosterImageView(
                url: posterURL,
                fixedSize: MainHomePosterCardMetrics.size
            )
        } else {
            Color(.secondarySystemFill)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

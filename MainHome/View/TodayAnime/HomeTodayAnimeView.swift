//
//  HomeTodayAnimeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct HomeTodayAnimeView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @ObservedObject private var viewModel: HomeTodayAnimeViewModel

    let showsHeader: Bool

    private let cardWidth: CGFloat = 240 * (2.0 / 3.0)

    // MARK: - Lifecycle

    init(
        viewModel: HomeTodayAnimeViewModel,
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
                    title: "今日動畫",
                    state: .navigable(action: { router.push(.todayAnimeSchedule) })
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
                        ErrorMessageView(state: .emptyCollection("尚無資料"), height: 240)
                            .frame(width: cardWidth)

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

private struct HomeTodayAnimeCardView: View {
    let item: HomeTodayAnimeCardItem
    let isFavorite: Bool

    @State private var imageSize: CGSize?

    private let cardSize = CGSize(width: 240 * (2.0 / 3.0), height: 240)

    private var imageContentMode: ContentMode {
        guard let imageSize, imageSize.width > imageSize.height else {
            return .fill
        }
        return .fit
    }

    var body: some View {
        PosterCardView {
            RemotePosterImageView(
                url: item.imageURL,
                contentMode: imageContentMode,
                onImageSizeChange: { size in
                    imageSize = size
                }
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
        .onChange(of: item.imageURL) { _, _ in
            imageSize = nil
        }
    }
}

#Preview {
    HomeTodayAnimeView(viewModel: HomeTodayAnimeViewModel())
        .environmentObject(FavoriteStatusStore())
        .environmentObject(MainHomeRouter())
}

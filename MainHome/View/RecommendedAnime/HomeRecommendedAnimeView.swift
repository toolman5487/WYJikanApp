//
//  HomeRecommendedAnimeView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/27.
//

import SwiftUI

struct HomeRecommendedAnimeView: View {
    @StateObject private var viewModel = HomeRecommendedAnimeViewModel()
    @EnvironmentObject private var router: MainHomeRouter

    private static let gridSpacing: CGFloat = 16
    private static let horizontalPadding: CGFloat = 16
    private static let skeletonCount: Int = 9
    private static let columnCount: Int = 3
    private static let loadMoreTopPadding: CGFloat = 8
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Self.gridSpacing, alignment: .top),
        count: Self.columnCount
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("推薦作品")
                .padding()
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.sakura)

            VStack(alignment: .leading, spacing: 0) {
                switch viewModel.viewState {
                case .loading:
                    LazyVGrid(columns: columns, alignment: .leading, spacing: Self.gridSpacing) {
                        ForEach(0..<Self.skeletonCount, id: \.self) { _ in
                            BannerSkeletonView()
                                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.horizontal, Self.horizontalPadding)
                case .failed(let errorMessage):
                    ErrorMessageView(message: errorMessage, height: 240)
                        .padding(.horizontal, Self.horizontalPadding)
                case .empty:
                    ErrorMessageView(message: "尚無推薦資料", height: 240)
                        .padding(.horizontal, Self.horizontalPadding)
                case .loaded:
                    LazyVGrid(columns: columns, alignment: .leading, spacing: Self.gridSpacing) {
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
                                    MyListCollectionStatusBadgeView(malId: item.detailMalId, mediaKind: .anime)
                                        .padding(8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Self.horizontalPadding)

                    if viewModel.canLoadMore {
                        Button("載入更多") {
                            viewModel.loadMore()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(ThemeColor.sakura)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.top, Self.loadMoreTopPadding)
                        .padding(.horizontal, Self.horizontalPadding)
                    }
                }
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
    HomeRecommendedAnimeView()
        .environmentObject(MainHomeRouter())
}

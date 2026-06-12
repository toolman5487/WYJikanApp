//
//  HomeWatchPromosView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI

struct HomeWatchPromosView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @ObservedObject private var viewModel: HomeWatchPromosViewModel
    @State private var endBounceProgress: CGFloat = 0

    let showsHeader: Bool
    let autoLoadOnAppear: Bool

    private let cardSize = MainHomePosterCardMetrics.size
    private let cornerRadius = MainHomePosterCardMetrics.cornerRadius

    // MARK: - Lifecycle

    init(
        viewModel: HomeWatchPromosViewModel,
        showsHeader: Bool = true,
        autoLoadOnAppear: Bool = true
    ) {
        self.viewModel = viewModel
        self.showsHeader = showsHeader
        self.autoLoadOnAppear = autoLoadOnAppear
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsHeader {
                GlassSectionHeaderView(title: "最新預告")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    switch viewModel.screenState {
                    case .loading:
                        ForEach(0..<10, id: \.self) { _ in
                            BannerSkeletonView()
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                                .frame(width: cardSize.width, height: cardSize.height)
                        }

                    case .error(let failure):
                        ErrorMessageView(state: ErrorMessageView.State(failure: failure), height: cardSize.height)
                            .frame(width: cardSize.width)

                    case .empty:
                        ErrorMessageView(state: .emptyCollection("尚無預告資料"), height: cardSize.height)
                            .frame(width: cardSize.width)

                    case .content:
                        ForEach(viewModel.items) { item in
                            Button {
                                openPromo(item)
                            } label: {
                                HomeWatchPromoCardView(
                                    item: item,
                                    cardSize: cardSize,
                                    cornerRadius: cornerRadius
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        EndBounceHintView(
                            axis: .horizontal,
                            title: "完整最新預告",
                            subtitle: "繼續往右拉查看影音列表",
                            progress: endBounceProgress,
                            width: cardSize.width,
                            height: cardSize.height,
                            cornerRadius: cornerRadius
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
                router.push(.watch(feed: .latestPromos))
            }
        }
        .onAppear {
            if autoLoadOnAppear {
                viewModel.loadIfNeeded()
            }
        }
    }

    // MARK: - Private Methods

    private func openPromo(_ item: HomeWatchPromoItem) {
        if let watchURL = item.watchURL {
            openExternally(.watchPromo(url: watchURL))
        } else {
            router.push(.animeDetail(malId: item.animeID))
        }
    }

    private func openExternally(_ page: BaseWebPage) {
        ExternalURLOpener.open(page.externalURLCandidates)
    }
}

private struct HomeWatchPromoCardView: View {
    let item: HomeWatchPromoItem
    let cardSize: CGSize
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            thumbnailView

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.78)
                ],
                startPoint: .center,
                endPoint: .bottom
            )

            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(ThemeColor.textPrimary.opacity(item.watchURL == nil ? 0.62 : 0.95))
                .shadow(radius: 8)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.promoTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.92))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(item.animeTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(12)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL = item.thumbnailURL {
            RemotePosterImageView(
                url: thumbnailURL,
                contentMode: .fill,
                fixedSize: cardSize
            )
        } else {
            Color(.secondarySystemBackground)
                .overlay {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(ThemeColor.textSecondary)
                }
        }
    }
}

#Preview {
    HomeWatchPromosView(viewModel: HomeWatchPromosViewModel(service: AppDependencies.live.homeWatchService))
        .environmentObject(MainHomeRouter())
}

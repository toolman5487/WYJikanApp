//
//  MainHomeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import SwiftUI

// MARK: - MainHomeView

struct MainHomeView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @StateObject private var heroBannerViewModel: HeroBannerViewModel
    @StateObject private var watchPromosViewModel: HomeWatchPromosViewModel
    @StateObject private var todayAnimeViewModel: HomeTodayAnimeViewModel
    @StateObject private var watchEpisodesViewModel: HomeWatchEpisodesViewModel
    @StateObject private var trendingMangaViewModel: HomeTrendingMangaViewModel
    @StateObject private var trendingAnimeViewModel: HomeTrendingAnimeViewModel
    @StateObject private var recommendedAnimeViewModel: HomeRecommendedAnimeViewModel
    @State private var feedCoordinator: HomeFeedCoordinator?
    @State private var loadMoreBounceProgress: CGFloat = 0
    private let dependencies: AppDependencies
    private let watchService: any HomeWatchServicing

    enum HomeSection: Identifiable {
        case watchPromos
        case todayAnime
        case watchEpisodes
        case trendingAnime
        case trendingManga
        case recommendedAnime

        var id: String {
            switch self {
            case .watchPromos: return "watchPromos"
            case .todayAnime: return "todayAnime"
            case .watchEpisodes: return "watchEpisodes"
            case .trendingAnime: return "trendingAnime"
            case .trendingManga: return "trendingManga"
            case .recommendedAnime: return "recommendedAnime"
            }
        }

        var title: String {
            switch self {
            case .watchPromos: return "最新預告"
            case .todayAnime: return "今日動畫"
            case .watchEpisodes: return "新上架集數"
            case .trendingAnime: return "熱門動畫"
            case .trendingManga: return "熱門漫畫"
            case .recommendedAnime: return "作品推薦"
            }
        }
    }

    private let sections: [HomeSection] = [
        .todayAnime,
        .trendingAnime,
        .trendingManga,
        .watchPromos,
        .watchEpisodes,
        .recommendedAnime
    ]

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        let service = dependencies.mainHomeService
        let watchService = dependencies.homeWatchService
        self.dependencies = dependencies
        self.watchService = watchService
        _heroBannerViewModel = StateObject(wrappedValue: HeroBannerViewModel(service: service))
        _watchPromosViewModel = StateObject(wrappedValue: HomeWatchPromosViewModel(service: watchService))
        _todayAnimeViewModel = StateObject(wrappedValue: HomeTodayAnimeViewModel(service: service))
        _watchEpisodesViewModel = StateObject(wrappedValue: HomeWatchEpisodesViewModel(service: watchService))
        _trendingAnimeViewModel = StateObject(wrappedValue: HomeTrendingAnimeViewModel(service: service))
        _trendingMangaViewModel = StateObject(wrappedValue: HomeTrendingMangaViewModel(service: service))
        _recommendedAnimeViewModel = StateObject(
            wrappedValue: HomeRecommendedAnimeViewModel(
                service: service,
                animeDetailService: dependencies.animeDetailService
            )
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    HeroBannerView(
                        viewModel: heroBannerViewModel,
                        autoLoadOnAppear: false
                    )
                    .ignoresSafeArea(edges: .top)

                    ForEach(sections) { section in
                        Section {
                            sectionView(section)
                        } header: {
                            sectionHeaderView(section)
                        }
                    }

                    if recommendedAnimeViewModel.canLoadMore {
                        EndBounceHintView(
                            axis: .vertical,
                            title: "載入更多",
                            subtitle: "繼續往下拉展開推薦",
                            progress: loadMoreBounceProgress
                        )
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .onEndBounce(
                axis: .vertical,
                isEnabled: recommendedAnimeViewModel.canLoadMore,
                progress: $loadMoreBounceProgress
            ) {
                recommendedAnimeViewModel.loadMore()
            }
            .onAppear {
                if feedCoordinator == nil {
                    feedCoordinator = makeFeedCoordinator()
                }
            }
            .refreshable {
                await refreshAllContent()
            }
            .task {
                await feedCoordinator?.loadInitial()
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: MainHomeRoute.self) { route in
                switch route {
                case .watch(let feed):
                    HomeWatchListView(
                        viewModel: dependencies.makeHomeWatchListViewModel(initialFeed: feed)
                    )
                case .webPage(let page):
                    BaseWebView(page: page)
                case .todayAnimeSchedule:
                    HomeTodayAnimeScheduleListView()
                case .trendingAnimeList:
                    HomeTrendingAnimeListView()
                case .trendingMangaList:
                    HomeTrendingMangaListView()
                case .animeDetail(let malId):
                    AnimeDetailView(malId: malId)
                case .mangaDetail(let malId):
                    MangaDetailView(malId: malId)
                }
            }
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func sectionView(_ section: HomeSection) -> some View {
        Group {
            switch section {
            case .watchPromos:
                HomeWatchPromosView(
                    viewModel: watchPromosViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .todayAnime:
                HomeTodayAnimeView(
                    viewModel: todayAnimeViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .watchEpisodes:
                HomeWatchEpisodesView(
                    viewModel: watchEpisodesViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .trendingAnime:
                HomeTrendingAnimeView(
                    viewModel: trendingAnimeViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .trendingManga:
                HomeTrendingMangaView(
                    viewModel: trendingMangaViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .recommendedAnime:
                HomeRecommendedAnimeView(
                    viewModel: recommendedAnimeViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            }
        }
        .task {
            if feedCoordinator == nil {
                feedCoordinator = makeFeedCoordinator()
            }
            guard let feedSection = homeFeedSection(for: section),
                  let coordinator = feedCoordinator else { return }
            await coordinator.loadSectionIfNeeded(feedSection)
        }
    }

    private func sectionHeaderView(_ section: HomeSection) -> some View {
        GlassSectionHeaderView(title: section.title, state: state(for: section))
            .padding(.horizontal, 16)
            .background(Color(.systemBackground).opacity(0.001))
    }

    private func state(for section: HomeSection) -> GlassSectionHeaderView.State {
        switch section {
        case .watchPromos:
            return .navigable(action: { router.push(.watch(feed: .latestPromos)) })
        case .todayAnime:
            return .navigable(action: { router.push(.todayAnimeSchedule) })
        case .watchEpisodes:
            return .navigable(action: { router.push(.watch(feed: .latestEpisodes)) })
        case .trendingAnime:
            return .navigable(action: { router.push(.trendingAnimeList) })
        case .trendingManga:
            return .navigable(action: { router.push(.trendingMangaList) })
        case .recommendedAnime:
            return .plain
        }
    }

    private func makeFeedCoordinator() -> HomeFeedCoordinator {
        HomeFeedCoordinator(
            viewModels: HomeFeedViewModels(
                heroBanner: heroBannerViewModel,
                todayAnime: todayAnimeViewModel,
                trendingAnime: trendingAnimeViewModel,
                trendingManga: trendingMangaViewModel,
                watchPromos: watchPromosViewModel,
                watchEpisodes: watchEpisodesViewModel,
                recommendedAnime: recommendedAnimeViewModel
            )
        )
    }

    private func homeFeedSection(for section: HomeSection) -> HomeFeedSection? {
        switch section {
        case .watchPromos:
            return .watchPromos
        case .todayAnime:
            return .todayAnime
        case .watchEpisodes:
            return .watchEpisodes
        case .trendingAnime:
            return .trendingAnime
        case .trendingManga:
            return .trendingManga
        case .recommendedAnime:
            return .recommendedAnime
        }
    }

    private func refreshAllContent() async {
        if feedCoordinator == nil {
            feedCoordinator = makeFeedCoordinator()
        }
        await feedCoordinator?.refreshAll()
    }
}

#Preview {
    MainHomeView(dependencies: .live)
        .environmentObject(MainHomeRouter.shared)
}

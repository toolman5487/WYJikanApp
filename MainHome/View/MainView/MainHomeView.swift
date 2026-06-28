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
    @State private var runtime: HomeFeedRuntime
    private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _runtime = State(initialValue: HomeFeedRuntime(dependencies: dependencies))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $router.path) {
            MainHomeFeedView(runtime: runtime)
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
}

// MARK: - HomeFeedRuntime

@MainActor
private final class HomeFeedRuntime {
    let heroBannerViewModel: HeroBannerViewModel
    let watchPromosViewModel: HomeWatchPromosViewModel
    let todayAnimeViewModel: HomeTodayAnimeViewModel
    let watchEpisodesViewModel: HomeWatchEpisodesViewModel
    let trendingMangaViewModel: HomeTrendingMangaViewModel
    let trendingAnimeViewModel: HomeTrendingAnimeViewModel
    let recommendedAnimeViewModel: HomeRecommendedAnimeViewModel
    let coordinator: HomeFeedCoordinator
    let tabRootViewModel: HomeTabRootViewModel

    init(dependencies: AppDependencies) {
        let service = dependencies.mainHomeService
        let watchService = dependencies.homeWatchService
        let heroBannerViewModel = HeroBannerViewModel(service: service)
        let watchPromosViewModel = HomeWatchPromosViewModel(service: watchService)
        let todayAnimeViewModel = HomeTodayAnimeViewModel(service: service)
        let watchEpisodesViewModel = HomeWatchEpisodesViewModel(service: watchService)
        let trendingMangaViewModel = HomeTrendingMangaViewModel(service: service)
        let trendingAnimeViewModel = HomeTrendingAnimeViewModel(service: service)
        let recommendedAnimeViewModel = HomeRecommendedAnimeViewModel(service: service)

        self.heroBannerViewModel = heroBannerViewModel
        self.watchPromosViewModel = watchPromosViewModel
        self.todayAnimeViewModel = todayAnimeViewModel
        self.watchEpisodesViewModel = watchEpisodesViewModel
        self.trendingMangaViewModel = trendingMangaViewModel
        self.trendingAnimeViewModel = trendingAnimeViewModel
        self.recommendedAnimeViewModel = recommendedAnimeViewModel
        self.coordinator = HomeFeedCoordinator(
            viewModels: HomeFeedViewModels(
                heroBanner: heroBannerViewModel,
                todayAnime: todayAnimeViewModel,
                trendingAnime: trendingAnimeViewModel,
                trendingManga: trendingMangaViewModel,
                watchPromos: watchPromosViewModel,
                watchEpisodes: watchEpisodesViewModel,
                recommendedAnime: recommendedAnimeViewModel
            ),
            homeFeedBootstrapCoordinator: dependencies.homeFeedBootstrapCoordinator,
            requestLifecycleController: dependencies.requestLifecycleManager
        )
        self.tabRootViewModel = HomeTabRootViewModel(coordinator: coordinator)
    }
}

// MARK: - MainHomeFeedView

private struct MainHomeFeedView: View {

    enum SectionKind: Identifiable {
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

    @EnvironmentObject private var router: MainHomeRouter
    @EnvironmentObject private var mainTabBarViewModel: MainTabBarViewModel
    @ObservedObject private var heroBannerViewModel: HeroBannerViewModel
    @ObservedObject private var watchPromosViewModel: HomeWatchPromosViewModel
    @ObservedObject private var todayAnimeViewModel: HomeTodayAnimeViewModel
    @ObservedObject private var watchEpisodesViewModel: HomeWatchEpisodesViewModel
    @ObservedObject private var trendingAnimeViewModel: HomeTrendingAnimeViewModel
    @ObservedObject private var trendingMangaViewModel: HomeTrendingMangaViewModel
    @ObservedObject private var recommendedAnimeViewModel: HomeRecommendedAnimeViewModel

    @State private var loadMoreBounceProgress: CGFloat = 0
    @State private var canLoadMoreRecommendations = false

    private let runtime: HomeFeedRuntime
    private let sections: [SectionKind] = [
        .todayAnime,
        .watchPromos,
        .watchEpisodes,
        .trendingAnime,
        .trendingManga,
        .recommendedAnime
    ]

    init(runtime: HomeFeedRuntime) {
        self.runtime = runtime
        _heroBannerViewModel = ObservedObject(wrappedValue: runtime.heroBannerViewModel)
        _watchPromosViewModel = ObservedObject(wrappedValue: runtime.watchPromosViewModel)
        _todayAnimeViewModel = ObservedObject(wrappedValue: runtime.todayAnimeViewModel)
        _watchEpisodesViewModel = ObservedObject(wrappedValue: runtime.watchEpisodesViewModel)
        _trendingAnimeViewModel = ObservedObject(wrappedValue: runtime.trendingAnimeViewModel)
        _trendingMangaViewModel = ObservedObject(wrappedValue: runtime.trendingMangaViewModel)
        _recommendedAnimeViewModel = ObservedObject(wrappedValue: runtime.recommendedAnimeViewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if !heroBannerViewModel.screenState.isFailed {
                    HeroBannerView(
                        viewModel: heroBannerViewModel,
                        autoLoadOnAppear: false
                    )
                    .ignoresSafeArea(edges: .top)
                }

                ForEach(visibleSections) { section in
                    Section {
                        sectionView(section)
                    } header: {
                        sectionHeaderView(section)
                    }
                }

                if !recommendedAnimeViewModel.screenState.isFailed {
                    HomeRecommendedAnimeLoadMoreFooter(
                        viewModel: recommendedAnimeViewModel,
                        progress: loadMoreBounceProgress,
                        onAvailabilityChange: { canLoadMore in
                            guard canLoadMoreRecommendations != canLoadMore else { return }
                            canLoadMoreRecommendations = canLoadMore
                        }
                    )
                }
            }
        }
        .onEndBounce(
            axis: .vertical,
            isEnabled: canLoadMoreRecommendations && !recommendedAnimeViewModel.screenState.isFailed,
            progress: $loadMoreBounceProgress
        ) {
            recommendedAnimeViewModel.loadMore()
        }
        .refreshable {
            await runtime.coordinator.refreshAll()
        }
        .tabRootLifecycle(viewModel: runtime.tabRootViewModel)
    }

    @ViewBuilder
    private func sectionView(_ section: SectionKind) -> some View {
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
        .task(id: mainTabBarViewModel.selectedTab, priority: .utility) {
            let platform = UserInterfacePlatform.current
            guard mainTabBarViewModel.selectedTab == .home,
                  platform.loadsHomeDeferredSectionsWhenVisible,
                  let feedSection = homeFeedSection(for: section) else { return }
            await runtime.coordinator.loadSectionIfNeeded(feedSection)
        }
    }

    private var visibleSections: [SectionKind] {
        sections.filter { !isSectionLoadFailed($0) }
    }

    private func isSectionLoadFailed(_ section: SectionKind) -> Bool {
        switch section {
        case .watchPromos:
            return watchPromosViewModel.screenState.isFailed
        case .todayAnime:
            return todayAnimeViewModel.screenState.isFailed
        case .watchEpisodes:
            return watchEpisodesViewModel.screenState.isFailed
        case .trendingAnime:
            return trendingAnimeViewModel.screenState.isFailed
        case .trendingManga:
            return trendingMangaViewModel.screenState.isFailed
        case .recommendedAnime:
            return recommendedAnimeViewModel.screenState.isFailed
        }
    }

    private func sectionHeaderView(_ section: SectionKind) -> some View {
        GlassSectionHeaderView(title: section.title, state: state(for: section))
            .padding(.horizontal, 16)
            .background(Color(.systemBackground).opacity(0.001))
    }

    private func state(for section: SectionKind) -> GlassSectionHeaderView.State {
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

    private func homeFeedSection(for section: SectionKind) -> HomeFeedSection? {
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
}

private struct HomeRecommendedAnimeLoadMoreFooter: View {

    @ObservedObject private var viewModel: HomeRecommendedAnimeViewModel

    let progress: CGFloat
    let onAvailabilityChange: (Bool) -> Void

    init(
        viewModel: HomeRecommendedAnimeViewModel,
        progress: CGFloat,
        onAvailabilityChange: @escaping (Bool) -> Void
    ) {
        self.viewModel = viewModel
        self.progress = progress
        self.onAvailabilityChange = onAvailabilityChange
    }

    var body: some View {
        Group {
            if viewModel.canLoadMore {
                EndBounceHintView(
                    axis: .vertical,
                    title: "載入更多",
                    subtitle: "繼續往下拉展開推薦",
                    progress: progress
                )
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            onAvailabilityChange(viewModel.canLoadMore)
        }
        .onChange(of: viewModel.canLoadMore) { _, canLoadMore in
            onAvailabilityChange(canLoadMore)
        }
    }
}

#Preview {
    MainHomeView(dependencies: .live)
        .environmentObject(MainHomeRouter.shared)
}

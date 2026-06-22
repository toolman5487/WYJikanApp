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

    init(dependencies: AppDependencies) {
        let service = dependencies.mainHomeService
        let watchService = dependencies.homeWatchService
        let heroBannerViewModel = HeroBannerViewModel(service: service)
        let watchPromosViewModel = HomeWatchPromosViewModel(service: watchService)
        let todayAnimeViewModel = HomeTodayAnimeViewModel(service: service)
        let watchEpisodesViewModel = HomeWatchEpisodesViewModel(service: watchService)
        let trendingMangaViewModel = HomeTrendingMangaViewModel(service: service)
        let trendingAnimeViewModel = HomeTrendingAnimeViewModel(service: service)
        let recommendedAnimeViewModel = HomeRecommendedAnimeViewModel(
            service: service,
            animeDetailService: dependencies.animeDetailService
        )

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
            )
        )
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
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                HeroBannerView(
                    viewModel: runtime.heroBannerViewModel,
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

                HomeRecommendedAnimeLoadMoreFooter(
                    viewModel: runtime.recommendedAnimeViewModel,
                    progress: loadMoreBounceProgress,
                    onAvailabilityChange: { canLoadMore in
                        guard canLoadMoreRecommendations != canLoadMore else { return }
                        canLoadMoreRecommendations = canLoadMore
                    }
                )
            }
        }
        .onEndBounce(
            axis: .vertical,
            isEnabled: canLoadMoreRecommendations,
            progress: $loadMoreBounceProgress
        ) {
            runtime.recommendedAnimeViewModel.loadMore()
        }
        .refreshable {
            await runtime.coordinator.refreshAll()
        }
        .task(priority: .userInitiated) {
            await runtime.coordinator.loadInitial()
        }
    }

    @ViewBuilder
    private func sectionView(_ section: SectionKind) -> some View {
        Group {
            switch section {
            case .watchPromos:
                HomeWatchPromosView(
                    viewModel: runtime.watchPromosViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .todayAnime:
                HomeTodayAnimeView(
                    viewModel: runtime.todayAnimeViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .watchEpisodes:
                HomeWatchEpisodesView(
                    viewModel: runtime.watchEpisodesViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .trendingAnime:
                HomeTrendingAnimeView(
                    viewModel: runtime.trendingAnimeViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .trendingManga:
                HomeTrendingMangaView(
                    viewModel: runtime.trendingMangaViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            case .recommendedAnime:
                HomeRecommendedAnimeView(
                    viewModel: runtime.recommendedAnimeViewModel,
                    showsHeader: false,
                    autoLoadOnAppear: false
                )
            }
        }
        .task(priority: .utility) {
            guard let feedSection = homeFeedSection(for: section) else { return }
            await runtime.coordinator.loadSectionIfNeeded(feedSection)
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

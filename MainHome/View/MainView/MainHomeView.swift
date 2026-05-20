//
//  MainHomeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import SwiftUI

struct MainHomeView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: MainHomeRouter
    @StateObject private var heroBannerViewModel: HeroBannerViewModel
    @StateObject private var todayAnimeViewModel: HomeTodayAnimeViewModel
    @StateObject private var trendingMangaViewModel: HomeTrendingMangaViewModel
    @StateObject private var trendingAnimeViewModel: HomeTrendingAnimeViewModel
    @StateObject private var recommendedAnimeViewModel: HomeRecommendedAnimeViewModel

    enum HomeSection: Identifiable {
        case todayAnime
        case trendingAnime
        case trendingManga
        case recommendedAnime

        var id: String {
            switch self {
            case .todayAnime: return "todayAnime"
            case .trendingAnime: return "trendingAnime"
            case .trendingManga: return "trendingManga"
            case .recommendedAnime: return "recommendedAnime"
            }
        }

        var title: String {
            switch self {
            case .todayAnime: return "今日動畫"
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
        .recommendedAnime
    ]

    // MARK: - Lifecycle

    init(service: MainHomeServicing = MainHomeService()) {
        _heroBannerViewModel = StateObject(wrappedValue: HeroBannerViewModel(service: service))
        _todayAnimeViewModel = StateObject(wrappedValue: HomeTodayAnimeViewModel(service: service))
        _trendingAnimeViewModel = StateObject(wrappedValue: HomeTrendingAnimeViewModel(service: service))
        _trendingMangaViewModel = StateObject(wrappedValue: HomeTrendingMangaViewModel(service: service))
        _recommendedAnimeViewModel = StateObject(wrappedValue: HomeRecommendedAnimeViewModel(service: service))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    HeroBannerView(viewModel: heroBannerViewModel)
                        .ignoresSafeArea(edges: .top)

                    ForEach(sections) { section in
                        Section {
                            sectionView(section)
                        } header: {
                            sectionHeaderView(section)
                        }
                    }
                }
            }
            .refreshable {
                await refreshAllContent()
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: MainHomeRoute.self) { route in
                switch route {
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
        switch section {
        case .todayAnime:
            HomeTodayAnimeView(
                viewModel: todayAnimeViewModel,
                showsHeader: false
            )
        case .trendingAnime:
            HomeTrendingAnimeView(
                viewModel: trendingAnimeViewModel,
                showsHeader: false
            )
        case .trendingManga:
            HomeTrendingMangaView(
                viewModel: trendingMangaViewModel,
                showsHeader: false
            )
        case .recommendedAnime:
            HomeRecommendedAnimeView(
                viewModel: recommendedAnimeViewModel,
                showsHeader: false
            )
        }
    }

    private func sectionHeaderView(_ section: HomeSection) -> some View {
        GlassSectionHeaderView(title: section.title, state: state(for: section))
            .padding(.horizontal, 16)
            .background(Color(.systemBackground).opacity(0.001))
    }

    private func state(for section: HomeSection) -> GlassSectionHeaderView.State {
        switch section {
        case .todayAnime:
            return .navigable(action: { router.push(.todayAnimeSchedule) })
        case .trendingAnime:
            return .navigable(action: { router.push(.trendingAnimeList) })
        case .trendingManga:
            return .navigable(action: { router.push(.trendingMangaList) })
        case .recommendedAnime:
            return .plain
        }
    }

    private func refreshAllContent() async {
        async let heroBannerRefresh = heroBannerViewModel.refresh()
        async let todayAnimeRefresh = todayAnimeViewModel.refresh()
        async let trendingAnimeRefresh = trendingAnimeViewModel.refresh()
        async let trendingMangaRefresh = trendingMangaViewModel.refresh()
        async let recommendedAnimeRefresh = recommendedAnimeViewModel.refresh()

        _ = await (
            heroBannerRefresh,
            todayAnimeRefresh,
            trendingAnimeRefresh,
            trendingMangaRefresh,
            recommendedAnimeRefresh
        )
    }
}

#Preview {
    MainHomeView()
        .environmentObject(MainHomeRouter.shared)
}

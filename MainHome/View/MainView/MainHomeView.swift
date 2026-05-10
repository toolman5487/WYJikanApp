//
//  MainHomeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import SwiftUI

struct MainHomeView: View {
    @StateObject private var router = MainHomeRouter()
    
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
    
    
    @ViewBuilder
    private func sectionView(_ section: HomeSection) -> some View {
        switch section {
        case .todayAnime:
            HomeTodayAnimeView(showsHeader: false)
        case .trendingAnime:
            HomeTrendingAnimeView(showsHeader: false)
        case .trendingManga:
            HomeTrendingMangaView(showsHeader: false)
        case .recommendedAnime:
            HomeRecommendedAnimeView(showsHeader: false)
        }
    }

    private func sectionHeaderView(_ section: HomeSection) -> some View {
        GlassSectionHeaderView(title: section.title, state: state(for: section))
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
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    HeroBannerView()
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
        .environmentObject(router)
    }
}

#Preview {
    MainHomeView()
}

//
//  MainHomeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import SwiftUI

struct MainHomeView: View {
    @StateObject private var router = MainHomeRouter()
    
    enum Section: Identifiable {
        case banner
        case todayAnime
        case trendingAnime
        case trendingManga
        case recommendedAnime
        
        var id: String {
            switch self {
            case .banner: return "banner"
            case .todayAnime: return "todayAnime"
            case .trendingAnime: return "trendingAnime"
            case .trendingManga: return "trendingManga"
            case .recommendedAnime: return "recommendedAnime"
            }
        }
    }
    
    private let sections: [Section] = [
        .banner,
        .todayAnime,
        .trendingAnime,
        .trendingManga,
        .recommendedAnime
    ]
    
    
    @ViewBuilder
    private func sectionView(_ section: Section) -> some View {
        switch section {
        case .banner:
            HeroBannerView()
        case .todayAnime:
            HomeTodayAnimeView()
        case .trendingAnime:
            HomeTrendingAnimeView()
        case .trendingManga:
            HomeTrendingMangaView()
        case .recommendedAnime:
            HomeRecommendedAnimeView()
        }
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView {
                LazyVStack {
                    ForEach(sections) { section in
                        sectionView(section)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: MainHomeRoute.self) { route in
                switch route {
                case .todayAnimeSchedule:
                    HomeTodayAnimeScheduleListView()
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

//
//  MainHomeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import SwiftUI

struct MainHomeView: View {
    enum Section: Identifiable {
        case banner
        case trendingAnime
        case trendingManga
        
        var id: String {
            switch self {
            case .banner: return "banner"
            case .trendingAnime: return "trendingAnime"
            case .trendingManga: return "trendingManga"
            }
        }
    }
    
    private let sections: [Section] = [
        .banner,
        .trendingAnime,
        .trendingManga
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sections) { section in
                    sectionView(section)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sectionView(_ section: Section) -> some View {
        switch section {
        case .banner:
            HeroBannerView()
        case .trendingAnime:
            HomeTrendingAnimeView()
        case .trendingManga:
            HomeTrendingMangaView()
        }
    }
}

#Preview {
    MainHomeView()
}

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
        
        var id: String {
            switch self {
            case .banner: return "banner"
            }
        }
    }
    
    private let sections: [Section] = [
        .banner
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
        }
    }
}

#Preview {
    MainHomeView()
}

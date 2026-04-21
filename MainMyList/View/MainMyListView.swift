//
//  MainMyListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MainMyListView: View {
    enum Section: Identifiable {
        case header
        case categoryFilter
        case summary
        case favorites

        var id: String {
            switch self {
            case .header: return "header"
            case .categoryFilter: return "categoryFilter"
            case .summary: return "summary"
            case .favorites: return "favorites"
            }
        }
    }

    private let sections: [Section] = [
        .header,
        .categoryFilter,
        .summary,
        .favorites
    ]

    @ViewBuilder
    private func sectionView(_ section: Section) -> some View {
        switch section {
        case .header:
            MyListHeaderSkeletonView()
        case .categoryFilter:
            MyListCategorySkeletonView()
        case .summary:
            MyListSummarySkeletonView()
        case .favorites:
            MyListFavoritesSkeletonView()
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(sections) { section in
                        sectionView(section)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("My List")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    MainMyListView()
}

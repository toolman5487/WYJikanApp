//
//  MainMyListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftData
import SwiftUI

struct MainMyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MyListCollectionItem.addedAt, order: .reverse)
    private var items: [MyListCollectionItem]
    @StateObject private var viewModel = MainMyListViewModel()
    
    private var filteredItems: [MyListCollectionItem] {
        viewModel.filteredItems(from: items)
    }
    
    private var animeCount: Int {
        viewModel.count(for: .anime, in: items)
    }
    
    private var mangaCount: Int {
        viewModel.count(for: .manga, in: items)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerView
                    filterView
                    summaryView
                    contentView
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("我的收藏")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var headerView: some View {
        Text("把想追的動畫與漫畫集中在這裡。")
            .font(.subheadline)
            .foregroundStyle(ThemeColor.textSecondary)
    }
    
    private var filterView: some View {
        CapsuleTagScrollView(
            tags: MainMyListViewModel.Filter.allCases,
            title: { $0.title },
            selection: $viewModel.selectedFilter
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var summaryView: some View {
        HStack(spacing: 12) {
            MyListSummaryTile(title: "全部", value: items.count, iconName: "heart.fill")
            MyListSummaryTile(title: "動畫", value: animeCount, iconName: MyListMediaKind.anime.iconName)
            MyListSummaryTile(title: "漫畫", value: mangaCount, iconName: MyListMediaKind.manga.iconName)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if filteredItems.isEmpty {
            MyListEmptyStateView(title: viewModel.emptyTitle(for: viewModel.selectedFilter))
        } else {
            LazyVStack(spacing: 12) {
                ForEach(filteredItems, id: \.persistentModelID) { item in
                    NavigationLink {
                        destinationView(for: item)
                    } label: {
                        MyListItemRowView(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.remove(item, from: modelContext)
                        } label: {
                            Label("移除收藏", systemImage: "heart.slash")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for item: MyListCollectionItem) -> some View {
        switch item.mediaKind {
        case .anime:
            AnimeDetailView(malId: item.malId)
        case .manga:
            MangaDetailView(malId: item.malId)
        }
    }
}

#Preview {
    MainMyListView()
}

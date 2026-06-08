//
//  MainMyListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftData
import SwiftUI

struct MainMyListView: View {
    private struct ItemRevision: Equatable {
        let id: PersistentIdentifier
        let malId: Int
        let mediaKindRawValue: String
        let title: String
        let subtitle: String?
        let imageURLString: String?
        let genreNamesRawValue: String?
        let type: String?
        let year: Int?
        let addedAt: Date
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MyListCollectionItem.addedAt, order: .reverse)
    private var items: [MyListCollectionItem]
    @StateObject private var viewModel = MainMyListViewModel()
    
    var body: some View {
        let presentation = viewModel.presentation

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerView
                    filterView
                    summaryView(presentation: presentation)
                    contentView(presentation: presentation)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("我的收藏")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.refreshPresentation(from: items)
        }
        .onChange(of: itemRevisions) { _, _ in
            viewModel.refreshPresentation(from: items)
        }
    }

    private var itemRevisions: [ItemRevision] {
        items.map { item in
            ItemRevision(
                id: item.persistentModelID,
                malId: item.malId,
                mediaKindRawValue: item.mediaKindRawValue,
                title: item.title,
                subtitle: item.subtitle,
                imageURLString: item.imageURLString,
                genreNamesRawValue: item.genreNamesRawValue,
                type: item.type,
                year: item.year,
                addedAt: item.addedAt
            )
        }
    }
    
    private var headerView: some View {
        Text("把想追的動畫與漫畫集中在這裡。")
            .font(.subheadline)
            .foregroundStyle(ThemeColor.textSecondary)
    }
    
    private var filterView: some View {
        CapsuleFilterBarView(
            tags: MainMyListViewModel.Filter.allCases,
            title: { $0.title },
            selection: $viewModel.selectedFilter
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func summaryView(presentation: MainMyListViewModel.Presentation) -> some View {
        MyListStatisticsSectionView(presentation: presentation)
    }
    
    @ViewBuilder
    private func contentView(presentation: MainMyListViewModel.Presentation) -> some View {
        if presentation.filteredItems.isEmpty {
            MyListEmptyStateView(title: viewModel.emptyTitle(for: viewModel.selectedFilter))
        } else {
            LazyVStack(spacing: 12) {
                ForEach(presentation.filteredItems, id: \.persistentModelID) { item in
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

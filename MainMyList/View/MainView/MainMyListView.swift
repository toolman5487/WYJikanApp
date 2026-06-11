//
//  MainMyListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftData
import SwiftUI

struct MainMyListView: View {
    // MARK: - Types

    private enum ContentState {
        case empty
        case populated
    }

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MyListCollectionItem.addedAt, order: .reverse)
    private var items: [MyListCollectionItem]
    @StateObject private var viewModel = MainMyListViewModel()
    @State private var genreCollectionsRoute: MyListGenreCollectionsRoute?
    @State private var formatCollectionsRoute: MyListFormatCollectionsRoute?

    // MARK: - Body

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
            .navigationDestination(item: $genreCollectionsRoute) { route in
                MyListGenreCollectionsDetailView(route: route)
            }
            .navigationDestination(item: $formatCollectionsRoute) { route in
                MyListFormatCollectionsDetailView(route: route)
            }
        }
        .onAppear {
            viewModel.refreshPresentation(from: items)
        }
        .onChange(of: itemRevisions) { _, _ in
            viewModel.refreshPresentation(from: items)
        }
    }

    // MARK: - Private Views

    private var headerView: some View {
        Text("把想追的動畫與漫畫集中在這裡。")
            .font(.subheadline)
            .foregroundStyle(ThemeColor.textSecondary)
    }

    private var filterView: some View {
        CapsuleFilterBarView(
            tags: MyListFilter.allCases,
            title: { $0.title },
            selection: $viewModel.selectedFilter
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryView(presentation: MyListPresentation) -> some View {
        MyListStatisticsSectionView(
            presentation: presentation,
            onSelectGenre: { genreName in
                showGenreCollectionsDetail(
                    selectedGenreName: genreName,
                    presentation: presentation
                )
            },
            onSelectFormat: { formatTitle in
                showFormatCollectionsDetail(
                    selectedFormatTitle: formatTitle,
                    presentation: presentation
                )
            }
        )
    }

    @ViewBuilder
    private func contentView(presentation: MyListPresentation) -> some View {
        switch contentState(for: presentation) {
        case .empty:
            MyListEmptyStateView(title: viewModel.emptyTitle(for: viewModel.selectedFilter))

        case .populated:
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

    // MARK: - Private Methods

    private var itemRevisions: [MyListItemRevision] {
        items.map { item in
            MyListItemRevision(
                id: item.persistentModelID,
                malId: item.malId,
                mediaKindRawValue: item.mediaKindRawValue,
                title: item.title,
                subtitle: item.subtitle,
                imageURLString: item.imageURLString,
                genreNamesRawValue: item.genreNamesRawValue,
                type: item.type,
                year: item.year,
                addedAt: item.addedAt,
                mangaReadingStatusRawValue: item.mangaReadingStatusRawValue,
                currentChapter: item.currentChapter,
                totalChaptersSnapshot: item.totalChaptersSnapshot,
                progressUpdatedAt: item.progressUpdatedAt
            )
        }
    }

    private func contentState(for presentation: MyListPresentation) -> ContentState {
        presentation.filteredItems.isEmpty ? .empty : .populated
    }

    private func showGenreCollectionsDetail(
        selectedGenreName: String,
        presentation: MyListPresentation
    ) {
        genreCollectionsRoute = MyListGenreCollectionsRoute(
            scopeTitle: presentation.statistics.selectedAnalysis.scope.title,
            genreSections: presentation.genreSections,
            selectedGenreName: selectedGenreName
        )
    }

    private func showFormatCollectionsDetail(
        selectedFormatTitle: String,
        presentation: MyListPresentation
    ) {
        formatCollectionsRoute = MyListFormatCollectionsRoute(
            scopeTitle: presentation.statistics.formatAnalysis.scope.title,
            formatSections: presentation.formatSections,
            selectedFormatTitle: selectedFormatTitle
        )
    }
}

#Preview {
    MainMyListView()
}

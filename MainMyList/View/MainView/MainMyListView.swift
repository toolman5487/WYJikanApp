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

    private enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let rowSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 16
    }

    // MARK: - Properties

    private let dependencies: AppDependencies

    @StateObject private var viewModel: MainMyListViewModel

    @State private var genreCollectionsRoute: MyListGenreCollectionsRoute?
    @State private var formatCollectionsRoute: MyListFormatCollectionsRoute?
    @State private var isShowingMangaReadingStatusQuery = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeMainMyListViewModel())
    }

    // MARK: - Body

    var body: some View {
        let presentation = viewModel.presentation

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    headerView
                    filterView
                    summaryView(presentation: presentation)
                    mangaReadingStatusEntryView(presentation: presentation)
                    contentView(presentation: presentation)
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, Layout.topPadding)
                .padding(.bottom, Layout.bottomPadding)
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
            .navigationDestination(isPresented: $isShowingMangaReadingStatusQuery) {
                MangaReadingStatusQueryView(dependencies: dependencies)
            }
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
    private func mangaReadingStatusEntryView(presentation: MyListPresentation) -> some View {
        if presentation.mangaReadingStatusSummary.totalCount > 0 {
            MangaReadingStatusEntryView(
                summary: presentation.mangaReadingStatusSummary
            ) {
                isShowingMangaReadingStatusQuery = true
            }
        }
    }

    @ViewBuilder
    private func contentView(presentation: MyListPresentation) -> some View {
        switch contentState(for: presentation) {
        case .empty:
            MyListEmptyStateView(emptyState: viewModel.emptyState())

        case .populated:
            LazyVStack(spacing: Layout.rowSpacing) {
                ForEach(presentation.filteredItems, id: \.persistentModelID) { item in
                    NavigationLink {
                        destinationView(for: item)
                    } label: {
                        MyListItemRowView(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.remove(item)
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
    MainMyListView(dependencies: .live)
}

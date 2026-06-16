//
//  MyListGenreCollectionsDetailView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/10.
//

import SwiftData
import SwiftUI

struct MyListGenreCollectionsDetailView: View {

    // MARK: - Types

    private enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let rowSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 20
        static let topPadding: CGFloat = 20
        static let bottomPadding: CGFloat = 32
    }

    // MARK: - Properties

    @StateObject private var viewModel: MyListGenreCollectionsDetailViewModel

    // MARK: - Lifecycle

    init(
        scopeTitle: String,
        genreSections: [MyListGenreCollectionSection],
        selectedGenreName: String
    ) {
        _viewModel = StateObject(
            wrappedValue: MyListGenreCollectionsDetailViewModel(
                scopeTitle: scopeTitle,
                genreSections: genreSections,
                selectedGenreName: selectedGenreName
            )
        )
    }

    init(route: MyListGenreCollectionsRoute) {
        _viewModel = StateObject(
            wrappedValue: MyListGenreCollectionsDetailViewModel(route: route)
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                genreFilterView

                if let selectedSection = viewModel.selectedSection {
                    LazyVStack(spacing: Layout.rowSpacing) {
                        ForEach(selectedSection.items, id: \.persistentModelID) { item in
                            NavigationLink {
                                destinationView(for: item)
                            } label: {
                                MyListItemRowView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    FeatureEmptyStateCardView(
                        emptyState: .filteredEmpty(
                            title: "沒有符合條件的收藏",
                            message: viewModel.emptyStateMessage
                        ),
                        minHeight: 160
                    )
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.topPadding)
            .padding(.bottom, Layout.bottomPadding)
        }
        .background(Color(.systemBackground))
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private Views

    private var genreFilterView: some View {
        CapsuleFilterBarView(
            tags: viewModel.filterTags,
            title: viewModel.localizedGenreName,
            selection: $viewModel.selectedGenreName
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Private Methods

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

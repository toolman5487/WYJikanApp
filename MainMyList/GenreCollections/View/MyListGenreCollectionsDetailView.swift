//
//  MyListGenreCollectionsDetailView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/10.
//

import SwiftData
import SwiftUI

struct MyListGenreCollectionsDetailView: View {
    @StateObject private var viewModel: MyListGenreCollectionsDetailViewModel

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

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                genreFilterView

                if let selectedSection = viewModel.selectedSection {
                    LazyVStack(spacing: 12) {
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
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var genreFilterView: some View {
        CapsuleFilterBarView(
            tags: viewModel.filterTags,
            title: viewModel.localizedGenreName,
            selection: $viewModel.selectedGenreName
        )
        .frame(maxWidth: .infinity, alignment: .leading)
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

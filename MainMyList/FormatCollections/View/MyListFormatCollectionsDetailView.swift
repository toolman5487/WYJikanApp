//
//  MyListFormatCollectionsDetailView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/10.
//

import SwiftData
import SwiftUI

struct MyListFormatCollectionsDetailView: View {
    @StateObject private var viewModel: MyListFormatCollectionsDetailViewModel

    init(
        scopeTitle: String,
        formatSections: [MyListFormatCollectionSection],
        selectedFormatTitle: String
    ) {
        _viewModel = StateObject(
            wrappedValue: MyListFormatCollectionsDetailViewModel(
                scopeTitle: scopeTitle,
                formatSections: formatSections,
                selectedFormatTitle: selectedFormatTitle
            )
        )
    }

    init(route: MyListFormatCollectionsRoute) {
        _viewModel = StateObject(
            wrappedValue: MyListFormatCollectionsDetailViewModel(route: route)
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                formatFilterView

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
                    ErrorMessageView(
                        state: .filteredEmpty(viewModel.emptyStateMessage),
                        height: 160
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

    private var formatFilterView: some View {
        CapsuleFilterBarView(
            tags: viewModel.filterTags,
            title: { $0 },
            systemImageName: viewModel.iconName(for:),
            selection: $viewModel.selectedFormatTitle
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

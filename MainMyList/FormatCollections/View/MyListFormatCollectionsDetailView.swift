//
//  MyListFormatCollectionsDetailView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/10.
//

import SwiftUI

struct MyListFormatCollectionsDetailView: View {

    // MARK: - Types

    private enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let rowSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 20
        static let topPadding: CGFloat = 20
        static let bottomPadding: CGFloat = 32
    }

    // MARK: - Properties

    @StateObject private var viewModel: MyListFormatCollectionsDetailViewModel

    // MARK: - Lifecycle

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

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                formatFilterView

                if let selectedSection = viewModel.selectedSection {
                    LazyVStack(spacing: Layout.rowSpacing) {
                        ForEach(selectedSection.items) { item in
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

    private var formatFilterView: some View {
        CapsuleFilterBarView(
            tags: viewModel.filterTags,
            title: { $0 },
            systemImageName: viewModel.iconName(for:),
            selection: $viewModel.selectedFormatTitle
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func destinationView(for item: MyListItemSnapshot) -> some View {
        switch item.mediaKind {
        case .anime:
            AnimeDetailView(malId: item.malId)
        case .manga:
            MangaDetailView(malId: item.malId)
        }
    }
}

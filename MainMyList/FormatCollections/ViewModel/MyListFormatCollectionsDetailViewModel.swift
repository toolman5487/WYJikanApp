//
//  MyListFormatCollectionsDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/10.
//

import Combine
import Foundation

@MainActor
final class MyListFormatCollectionsDetailViewModel: ObservableObject {

    // MARK: - Properties

    let scopeTitle: String
    let formatSections: [MyListFormatCollectionSection]
    @Published var selectedFormatTitle: String

    // MARK: - Lifecycle

    init(
        scopeTitle: String,
        formatSections: [MyListFormatCollectionSection],
        selectedFormatTitle: String
    ) {
        self.scopeTitle = scopeTitle
        self.formatSections = formatSections
        self.selectedFormatTitle = Self.resolvedFormatTitle(
            selectedFormatTitle,
            in: formatSections
        )
    }

    convenience init(route: MyListFormatCollectionsRoute) {
        self.init(
            scopeTitle: route.scopeTitle,
            formatSections: route.formatSections,
            selectedFormatTitle: route.selectedFormatTitle
        )
    }

    // MARK: - Presentation

    var navigationTitle: String {
        "\(scopeTitle)形式收藏"
    }

    var filterTags: [String] {
        formatSections.map(\.title)
    }

    var selectedSection: MyListFormatCollectionSection? {
        formatSections.first { $0.title == selectedFormatTitle }
    }

    var emptyStateMessage: String {
        "尚無此形式收藏"
    }

    // MARK: - Actions

    func iconName(for title: String) -> String? {
        formatSections.first { $0.title == title }?.iconName
    }

    func selectFormat(_ title: String) {
        selectedFormatTitle = Self.resolvedFormatTitle(title, in: formatSections)
    }

    // MARK: - Private Methods

    private static func resolvedFormatTitle(
        _ title: String,
        in formatSections: [MyListFormatCollectionSection]
    ) -> String {
        if formatSections.contains(where: { $0.title == title }) {
            return title
        }

        return formatSections.first?.title ?? title
    }
}

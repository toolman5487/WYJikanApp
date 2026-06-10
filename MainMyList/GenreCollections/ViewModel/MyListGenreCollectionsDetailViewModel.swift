//
//  MyListGenreCollectionsDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/10.
//

import Combine
import Foundation

@MainActor
final class MyListGenreCollectionsDetailViewModel: ObservableObject {
    let scopeTitle: String
    let genreSections: [MyListGenreCollectionSection]
    @Published var selectedGenreName: String

    init(
        scopeTitle: String,
        genreSections: [MyListGenreCollectionSection],
        selectedGenreName: String
    ) {
        self.scopeTitle = scopeTitle
        self.genreSections = genreSections
        self.selectedGenreName = Self.resolvedGenreName(
            selectedGenreName,
            in: genreSections
        )
    }

    convenience init(route: MyListGenreCollectionsRoute) {
        self.init(
            scopeTitle: route.scopeTitle,
            genreSections: route.genreSections,
            selectedGenreName: route.selectedGenreName
        )
    }

    var navigationTitle: String {
        "\(scopeTitle)種類收藏"
    }

    var filterTags: [String] {
        genreSections.map(\.genreName)
    }

    var selectedSection: MyListGenreCollectionSection? {
        genreSections.first { $0.genreName == selectedGenreName }
    }

    var emptyStateMessage: String {
        "尚無此種類收藏"
    }

    func localizedGenreName(_ genreName: String) -> String {
        AnimeGenreLocalizationModel.localizedName(for: genreName)
    }

    func selectGenre(_ genreName: String) {
        selectedGenreName = Self.resolvedGenreName(genreName, in: genreSections)
    }

    private static func resolvedGenreName(
        _ genreName: String,
        in genreSections: [MyListGenreCollectionSection]
    ) -> String {
        if genreSections.contains(where: { $0.genreName == genreName }) {
            return genreName
        }

        return genreSections.first?.genreName ?? genreName
    }
}

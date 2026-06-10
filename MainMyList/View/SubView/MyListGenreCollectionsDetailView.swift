//
//  MyListGenreCollectionsDetailView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/10.
//

import SwiftData
import SwiftUI

struct MyListGenreCollectionsDetailView: View {
    let scopeTitle: String
    let genreSections: [MyListGenreCollectionSection]
    @State private var selectedGenreName: String

    init(
        scopeTitle: String,
        genreSections: [MyListGenreCollectionSection],
        selectedGenreName: String
    ) {
        self.scopeTitle = scopeTitle
        self.genreSections = genreSections
        let resolvedGenreName = Self.resolvedGenreName(
            selectedGenreName,
            in: genreSections
        )
        _selectedGenreName = State(initialValue: resolvedGenreName)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                genreFilterView

                if let selectedSection {
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
                        state: .emptyCollection("尚無此種類收藏"),
                        height: 160
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationTitle("\(scopeTitle)種類收藏")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var genreFilterView: some View {
        CapsuleFilterBarView(
            tags: genreSections.map(\.genreName),
            title: localizedGenreName,
            selection: selectedGenreBinding
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectedGenreBinding: Binding<String> {
        Binding(
            get: {
                Self.resolvedGenreName(selectedGenreName, in: genreSections)
            },
            set: { newValue in
                selectedGenreName = newValue
            }
        )
    }

    private var selectedSection: MyListGenreCollectionSection? {
        genreSections.first { $0.genreName == selectedGenreBinding.wrappedValue }
    }

    private func localizedGenreName(_ genreName: String) -> String {
        AnimeGenreLocalizationModel.localizedName(for: genreName)
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

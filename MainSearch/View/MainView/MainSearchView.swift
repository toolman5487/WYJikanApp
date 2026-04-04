//
//  MainSearchView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MainSearchView: View {

    @Bindable var viewModel: MainSearchViewModel

    private var trimmedQuery: String {
        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var bodyState: MainSearchBodyState {
        MainSearchBodyState.resolve(
            trimmedQuery: trimmedQuery,
            query: viewModel.query,
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            rows: viewModel.rows
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CapsuleTagScrollView(
                    tags: MainSearchKind.allCases,
                    title: { $0.title },
                    selection: $viewModel.kind
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                MainSearchResultsContentView(bodyState: bodyState)
            }
            .navigationDestination(for: MainSearchResultRow.self) { row in
                destinationView(for: row)
            }
        }
        .searchable(text: $viewModel.query, prompt: viewModel.kind.searchPrompt)
        .onChange(of: viewModel.query) { _, _ in
            viewModel.scheduleSearch()
        }
        .onChange(of: viewModel.kind) { _, _ in
            viewModel.scheduleSearch()
        }
        .onAppear {
            viewModel.scheduleSearch()
        }
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destinationView(for row: MainSearchResultRow) -> some View {
        switch row.kind {
        case .anime:
            AnimeDetailView(malId: row.malId)
        case .manga:
            MangaDetailView(malId: row.malId)
        case .character, .people:
            MainSearchMALStubView(title: row.title, malPageURL: row.malPageURL)
        }
    }
}

#Preview {
    MainSearchView(viewModel: MainSearchViewModel())
}

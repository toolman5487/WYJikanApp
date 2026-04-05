//
//  MainSearchView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MainSearchView: View {

    @ObservedObject var viewModel: MainSearchViewModel

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

                MainSearchResultsContentView(bodyState: viewModel.bodyState)
            }
            .navigationDestination(for: MainSearchResultRow.self) { row in
                MainSearchRouter.destination(for: row)
            }
        }
        .searchable(text: $viewModel.query, prompt: viewModel.kind.searchPrompt)
    }
}

#Preview {
    struct MainSearchPreview: View {
        @StateObject private var viewModel = MainSearchViewModel()
        var body: some View {
            MainSearchView(viewModel: viewModel)
        }
    }
    return MainSearchPreview()
}

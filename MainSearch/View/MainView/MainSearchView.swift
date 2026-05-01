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
                MainSearchResultsContentView(
                    screenState: viewModel.screenState,
                    isLoadingMore: viewModel.isLoadingMore,
                    loadMoreErrorMessage: viewModel.loadMoreErrorMessage,
                    onRowAppear: viewModel.loadMoreIfNeeded(currentRow:),
                    onRetryLoadMore: viewModel.retryLoadMore
                )
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    CapsuleTagScrollView(
                        tags: MainSearchKind.allCases,
                        title: { $0.title },
                        selection: $viewModel.kind
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Menu {
                        ForEach(MainSearchSortOption.supportedOptions(for: viewModel.kind), id: \.self) { option in
                            Button {
                                viewModel.sortOption = option
                            } label: {
                                Label(option.title, systemImage: option.systemImageName)
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(ThemeColor.textPrimary)
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel("排序方式")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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

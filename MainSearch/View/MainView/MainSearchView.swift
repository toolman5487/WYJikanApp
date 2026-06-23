//
//  MainSearchView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MainSearchView: View {

    // MARK: - Properties

    @EnvironmentObject private var mainTabBarViewModel: MainTabBarViewModel
    @ObservedObject var viewModel: MainSearchViewModel
    @State private var loadMoreBounceProgress: CGFloat = 0

    // MARK: - Body

    var body: some View {
        searchNavigationStack
            .searchable(text: $viewModel.query, prompt: viewModel.kind.searchPrompt)
            .onSubmit(of: .search) {
                viewModel.submitSearch()
            }
            .task(id: mainTabBarViewModel.selectedTab, priority: .userInitiated) {
                await handleSelectedTabChange()
            }
            .onDisappear {
                viewModel.screenDidDisappear()
            }
    }

    private func handleSelectedTabChange() async {
        guard mainTabBarViewModel.selectedTab == .searchLiquidGlass else {
            viewModel.screenDidDisappear()
            return
        }

        await viewModel.screenDidAppear()
    }

    // MARK: - Private Views

    private var searchNavigationStack: some View {
        NavigationStack {
            MainSearchResultsContentView(
                screenState: viewModel.screenState,
                loadMoreState: viewModel.loadMoreState,
                isLoadMoreEnabled: viewModel.canLoadMoreFromEndBounce,
                loadMoreProgress: $loadMoreBounceProgress,
                searchHistory: viewModel.searchHistory,
                filterHeader: { filterHeader },
                onRowAppear: { _ in },
                onLoadMore: viewModel.loadMoreFromEndBounce,
                onRetryLoadMore: viewModel.retryLoadMore,
                onSelectHistory: viewModel.applyHistory,
                onRemoveHistory: viewModel.removeHistoryItem,
                onClearHistory: viewModel.clearSearchHistory
            )
            .navigationDestination(for: MainSearchResultRow.self) { row in
                MainSearchRouter.destination(for: row)
            }
        }
    }

    private var filterHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            CapsuleFilterBarView(
                tags: MainSearchKind.allCases,
                title: { $0.title },
                selection: $viewModel.kind
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            sortMenu
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(
                MainSearchSortOption.supportedOptions(for: viewModel.kind),
                id: \.self
            ) { option in
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
    }
}

// MARK: - Preview

#Preview {
    struct MainSearchPreview: View {
        @StateObject private var viewModel = AppDependencies.live.makeMainSearchViewModel()

        var body: some View {
            MainSearchView(viewModel: viewModel)
                .environmentObject(MainTabBarViewModel())
        }
    }

    return MainSearchPreview()
}

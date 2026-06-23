//
//  MainTabBarView.swift
//  WYJikanApp
//

import SwiftUI

struct MainTabBarView: View {
    @Environment(\.appDependencies) private var dependencies

    var body: some View {
        MainTabBarConfiguredView(dependencies: dependencies)
    }
}

private struct MainTabBarConfiguredView: View {

    // MARK: - Properties

    let dependencies: AppDependencies

    @EnvironmentObject private var viewModel: MainTabBarViewModel
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var mainSearchViewModel: MainSearchViewModel

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _mainSearchViewModel = StateObject(
            wrappedValue: dependencies.makeMainSearchViewModel()
        )
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            TabSection("主頁") {
                Tab(value: AppTab.home) {
                    MainHomeView(dependencies: dependencies)
                } label: {
                    Image(systemName: viewModel.selectedTab == .home ? "square.grid.3x3.fill" : "square.grid.3x3")
                }

                Tab(value: AppTab.categorylist) {
                    MainCategoryListView(dependencies: dependencies)
                } label: {
                    Image(systemName: viewModel.selectedTab == .categorylist ? "film.stack.fill" : "film.stack")
                }

                Tab(value: AppTab.news) {
                    MainNewsView(dependencies: dependencies)
                } label: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .symbolVariant(viewModel.selectedTab == .news ? .fill : .none)
                }

                Tab(value: AppTab.myList) {
                    MainMyListView(dependencies: dependencies.myList)
                } label: {
                    Image(systemName: viewModel.selectedTab == .myList ? "heart.fill" : "heart")
                }
                .badge(myListBadgeText)
            }

            TabSection("搜尋") {
                Tab(value: AppTab.searchLiquidGlass, role: .search) {
                    MainSearchView(viewModel: mainSearchViewModel)
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .tint(ThemeColor.sakura)
        .tabViewStyle(.sidebarAdaptable)
        .toolbarBackground(.visible, for: .tabBar)
        .tabBarMinimizeBehavior(.onScrollDown)
        .task(id: viewModel.selectedTab) {
            await JikanAPIService.shared.setActiveRequestScope(
                viewModel.selectedTab.requestScope
            )
        }
        .onChange(of: viewModel.selectedTab) { _, selectedTab in
            viewModel.handleSelectedTabChange(
                selectedTab,
                favoriteCount: favoriteStatusStore.totalFavoriteCount
            )
        }
        .onChange(of: favoriteStatusStore.totalFavoriteCount) { _, favoriteCount in
            viewModel.handleFavoriteCountChange(favoriteCount)
        }
    }

    private var myListBadgeText: Text? {
        let count = viewModel.myListBadgeCount(
            favoriteCount: favoriteStatusStore.totalFavoriteCount
        )
        guard count > 0 else { return nil }
        return Text("\(count)")
    }
}

#Preview {
    MainTabBarView()
        .environmentObject(AppPersistenceStore())
        .environmentObject(MainTabBarViewModel())
        .environmentObject(FavoriteStatusStore())
        .environmentObject(MainHomeRouter.shared)
}

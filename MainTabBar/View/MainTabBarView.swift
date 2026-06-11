//
//  MainTabBarView.swift
//  WYJikanApp
//

import SwiftUI

struct MainTabBarView: View {

    // MARK: - Properties

    @EnvironmentObject private var viewModel: MainTabBarViewModel
    @EnvironmentObject private var favoriteStatusStore: FavoriteStatusStore
    @StateObject private var mainSearchViewModel = MainSearchViewModel()

    // MARK: - Body

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            TabSection("主頁") {
                Tab(value: AppTab.home) {
                    MainHomeView()
                } label: {
                    Image(systemName: viewModel.selectedTab == .home ? "square.grid.3x3.fill" : "square.grid.3x3")
                }

                Tab(value: AppTab.categorylist) {
                    MainCategoryListView()
                } label: {
                    Image(systemName: viewModel.selectedTab == .categorylist ? "film.stack.fill" : "film.stack")
                }

                Tab(value: AppTab.news) {
                    MainNewsView()
                } label: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .symbolVariant(viewModel.selectedTab == .news ? .fill : .none)
                }

                Tab(value: AppTab.myList) {
                    MainMyListView()
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
        .environmentObject(MainTabBarViewModel.shared)
        .environmentObject(FavoriteStatusStore())
        .environmentObject(MainHomeRouter.shared)
}

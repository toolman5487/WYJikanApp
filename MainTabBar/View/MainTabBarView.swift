//
//  MainTabBarView.swift
//  WYJikanApp
//

import SwiftUI

struct MainTabBarView: View {
    @State private var viewModel = MainTabBarViewModel()
    @StateObject private var mainSearchViewModel = MainSearchViewModel()
    
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
                
                Tab(value: AppTab.myList) {
                    MainMyListView()
                } label: {
                    Image(systemName: viewModel.selectedTab == .myList ? "heart.fill" : "heart")
                }
            }
            
            TabSection("搜尋") {
                Tab(value: AppTab.searchLiquidGlass, role: .search) {
                    MainSearchView(viewModel: mainSearchViewModel)
                } label: {
                    Image(systemName: viewModel.selectedTab == .searchLiquidGlass ? "magnifyingglass" : "magnifyingglass")
                }
            }
        }
        .tint(ThemeColor.sakura)
        .tabViewStyle(.sidebarAdaptable)
        .toolbarBackground(.visible, for: .tabBar)
        .tabBarMinimizeBehavior(.automatic)
    }
}

#Preview {
    MainTabBarView()
}

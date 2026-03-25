//
//  MainTabBarView.swift
//  WYJikanApp
//

import SwiftUI

struct MainTabBarView: View {
    @State private var viewModel = MainTabBarViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            TabSection("主頁") {
                Tab(value: AppTab.home) {
                    MainHomeView()
                } label: {
                    Image(systemName: viewModel.selectedTab == .home ? "square.grid.3x3.fill" : "square.grid.3x3")
                        .accessibilityLabel("首頁")
                }
                
                Tab(value: AppTab.category) {
                    NavigationStack {
                        PlaceholderView()
                    }
                } label: {
                    Image(systemName: viewModel.selectedTab == .category ? "rectangle.stack.fill" : "rectangle.stack")
                        .accessibilityLabel("分類")
                }
                
                Tab(value: AppTab.myList) {
                    PlaceholderView()
                } label: {
                    Image(systemName: viewModel.selectedTab == .myList ? "heart.fill" : "heart")
                        .accessibilityLabel("收藏")
                }
            }
            
            TabSection("搜尋") {
                Tab(value: AppTab.searchLiquidGlass, role: .search) {
                    NavigationStack {
                        PlaceholderView()
                            .searchable(text: $viewModel.searchQuery, prompt: "搜尋動畫")
                    }
                } label: {
                    Image(systemName: viewModel.selectedTab == .searchLiquidGlass ? "magnifyingglass" : "magnifyingglass")
                        .accessibilityLabel("搜尋")
                }
            }
        }
        .tint(.blue)
        .tabViewStyle(.sidebarAdaptable)
        .toolbarBackground(.visible, for: .tabBar)
        .tabBarMinimizeBehavior(.automatic)
    }
}

#Preview {
    MainTabBarView()
}

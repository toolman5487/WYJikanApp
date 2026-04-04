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
                }
                
                Tab(value: AppTab.category) {
                    NavigationStack {
                        PlaceholderView(placeholderName: "category")
                    }
                } label: {
                    Image(systemName: viewModel.selectedTab == .category ? "rectangle.stack.fill" : "rectangle.stack")
                }
                
                Tab(value: AppTab.myList) {
                    PlaceholderView(placeholderName: "myList")
                } label: {
                    Image(systemName: viewModel.selectedTab == .myList ? "heart.fill" : "heart")
                }
            }
            
            TabSection("搜尋") {
                Tab(value: AppTab.searchLiquidGlass, role: .search) {
                    NavigationStack {
                      MainSearchView(selectedKind: $viewModel.searchKind)
                            .searchable(text: $viewModel.searchQuery, prompt: viewModel.searchKind.searchPrompt)
                    }
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

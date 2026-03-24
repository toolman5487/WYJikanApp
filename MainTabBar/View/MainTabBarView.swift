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
                    PlaceholderView()
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

// MARK: - TabView 常用 Modifier 參考
//
// .tabViewStyle(...)
//   - .automatic         預設，依平台自動
//   - .sidebarAdaptable  支援 TabSection，iPad 側邊欄 / iPhone Tab Bar
//   - .tabBarOnly        僅 Tab Bar
//   - .grouped           分組 Tab Bar
//   - .page              滑動分頁（無 Tab Bar）
//   - .verticalPage      垂直滑動分頁
//   - .carousel          輪播
//
// .tint(Color)                             選中圖示與強調色
// .toolbarBackground(_, for: .tabBar)      Tab Bar 背景樣式
// .toolbarBackground(.visible, for: .tabBar) 顯示 Tab Bar 背景
// .toolbarColorScheme(nil, for: .tabBar)   nil = 跟隨系統；.dark / .light = 強制
// .tabBarMinimizeBehavior(...)
//   - .automatic         預設
//   - .never             不縮小
//   - .onScrollDown      向下滑動時縮小 (iPhone)
//   - .onScrollUp        向上滑動時縮小 (iPhone)
//
// .tabViewCustomization($customization)     Tab 自訂（拖曳、隱藏）需 @AppStorage TabViewCustomization

#Preview {
    MainTabBarView()
}

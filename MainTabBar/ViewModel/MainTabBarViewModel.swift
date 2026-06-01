//
//  MainTabBarViewModel.swift
//  WYJikanApp
//

import Combine

enum AppTab: Hashable {
    case home
    case categorylist
    case myList
    case searchLiquidGlass
}

@MainActor
final class MainTabBarViewModel: ObservableObject {
    static let shared = MainTabBarViewModel()

    @Published
    var selectedTab: AppTab = .home
}

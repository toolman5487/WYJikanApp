//
//  MainTabBarViewModel.swift
//  WYJikanApp
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case category
    case myList
    case searchLiquidGlass
}

@MainActor
@Observable
final class MainTabBarViewModel {
    var selectedTab: AppTab = .home
}

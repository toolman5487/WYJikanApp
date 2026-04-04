//
//  MainTabBarViewModel.swift
//  WYJikanApp
//

import SwiftUI
import Combine

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
    var searchQuery = ""
    var searchKind: MainSearchKind = .anime
}

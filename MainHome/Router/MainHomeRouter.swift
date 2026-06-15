//
//  MainHomeRouter.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Combine
import Foundation
import SwiftUI

// MARK: - MainHomeRoute

enum MainHomeRoute: Hashable {
    case watch(feed: HomeWatchFeedKind)
    case webPage(BaseWebPage)
    case todayAnimeSchedule
    case trendingAnimeList
    case trendingMangaList
    case animeDetail(malId: Int)
    case mangaDetail(malId: Int)
}

// MARK: - MainHomeRouter

@MainActor
final class MainHomeRouter: ObservableObject {
    static let shared = MainHomeRouter()

    // MARK: - Properties

    @Published var path = NavigationPath()

    // MARK: - Public Methods

    func push(_ route: MainHomeRoute) {
        path.append(route)
    }

    func replacePath(with routes: [MainHomeRoute]) {
        path = NavigationPath()
        for route in routes {
            path.append(route)
        }
    }
}

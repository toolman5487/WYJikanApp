//
//  MainHomeRouter.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Combine
import Foundation
import SwiftUI

enum MainHomeRoute: Hashable {
    case todayAnimeSchedule
    case trendingAnimeList
    case trendingMangaList
    case animeDetail(malId: Int)
    case mangaDetail(malId: Int)
}

@MainActor
final class MainHomeRouter: ObservableObject {
    static let shared = MainHomeRouter()

    @Published var path = NavigationPath()

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

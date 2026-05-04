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
    case animeDetail(malId: Int)
    case mangaDetail(malId: Int)
}

@MainActor
final class MainHomeRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: MainHomeRoute) {
        path.append(route)
    }
}

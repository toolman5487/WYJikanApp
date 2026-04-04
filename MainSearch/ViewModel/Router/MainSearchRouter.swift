//
//  MainSearchRouter.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

enum MainSearchRouter {

    @ViewBuilder
    static func destination(for row: MainSearchResultRow) -> some View {
        switch row.kind {
        case .anime:
            AnimeDetailView(malId: row.malId)
        case .manga:
            MangaDetailView(malId: row.malId)
        case .character, .people:
            NavigationWebPageView(title: row.title, url: row.malPageURL)
        }
    }
}

//
//  MyListCollectionStatusBadgeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import SwiftData
import SwiftUI

struct MyListCollectionStatusBadgeView: View {
    private enum FavoriteSource {
        case query
        case explicit(Bool)
    }

    @Query private var matches: [MyListCollectionItem]
    private let favoriteSource: FavoriteSource

    init(malId: Int, mediaKind: MyListMediaKind) {
        let mediaKindRawValue = mediaKind.rawValue
        favoriteSource = .query
        _matches = Query(
            filter: #Predicate<MyListCollectionItem> {
                $0.malId == malId && $0.mediaKindRawValue == mediaKindRawValue
            }
        )
    }

    init(isFavorite: Bool) {
        favoriteSource = .explicit(isFavorite)
        _matches = Query(filter: #Predicate<MyListCollectionItem> { _ in false })
    }

    private var isFavorite: Bool {
        switch favoriteSource {
        case .query:
            return !matches.isEmpty
        case .explicit(let isFavorite):
            return isFavorite
        }
    }

    var body: some View {
        Image(systemName: isFavorite ? "heart.fill" : "heart")
            .font(.caption.weight(.bold))
            .foregroundStyle(ThemeColor.sakura)
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

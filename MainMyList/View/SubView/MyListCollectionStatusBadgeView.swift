//
//  MyListCollectionStatusBadgeView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import SwiftData
import SwiftUI

struct MyListCollectionStatusBadgeView: View {
    @Query private var matches: [MyListCollectionItem]

    init(malId: Int, mediaKind: MyListMediaKind) {
        let mediaKindRawValue = mediaKind.rawValue
        _matches = Query(
            filter: #Predicate<MyListCollectionItem> {
                $0.malId == malId && $0.mediaKindRawValue == mediaKindRawValue
            }
        )
    }

    private var isFavorite: Bool {
        !matches.isEmpty
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

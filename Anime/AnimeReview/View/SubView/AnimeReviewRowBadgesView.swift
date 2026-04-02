//
//  AnimeReviewRowBadgesView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewRowBadgesView: View {

    let entry: AnimeReviewEntryDTO

    var body: some View {
        if entry.isSpoiler == true || entry.isPreliminary == true {
            VStack(alignment: .leading, spacing: 4) {
                if entry.isSpoiler == true {
                    Text("可能含有劇透")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }
                if entry.isPreliminary == true {
                    Text("觀看進度未滿")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ThemeColor.textSecondary)
                }
            }
        }
    }
}

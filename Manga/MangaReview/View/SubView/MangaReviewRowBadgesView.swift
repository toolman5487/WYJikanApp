//
//  MangaReviewRowBadgesView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MangaReviewRowBadgesView: View {

    let entry: MangaReviewEntryDTO

    var body: some View {
        if entry.isSpoiler == true || entry.isPreliminary == true {
            VStack(alignment: .leading, spacing: 4) {
                if entry.isSpoiler == true {
                    Text("可能含有劇透")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }
                if entry.isPreliminary == true {
                    Text("閱讀進度未滿")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ThemeColor.textSecondary)
                }
            }
        }
    }
}

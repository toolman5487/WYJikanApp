//
//  MangaDetailRecommendationsListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct MangaDetailRecommendationsListView: View {
    let mangaTitle: String
    let rows: [DetailRecommendationRow]

    var body: some View {
        DetailPosterGridListLayout {
            ForEach(rows) { row in
                NavigationLink {
                    MangaDetailView(malId: row.malId)
                } label: {
                    AnimeDetailRecommendationCardView(row: row)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("\(mangaTitle) 推薦")
        .navigationBarTitleDisplayMode(.inline)
    }
}

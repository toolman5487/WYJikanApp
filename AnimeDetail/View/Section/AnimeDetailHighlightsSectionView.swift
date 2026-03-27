//
//  AnimeDetailHighlightsSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailHighlightsSectionView: View {
    let anime: AnimeDetailDTO
    
    var body: some View {
        if !highlightItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("重點資訊")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(highlightItems, id: \.title) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundStyle(ThemeColor.textPrimary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                Text(item.value)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(ThemeColor.textPrimary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 72, alignment: .topLeading)
                            .background(ThemeColor.sakura)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            }
        }
    }
    
    private var highlightItems: [(title: String, value: String)] {
        var items: [(String, String)] = []
        if let type = anime.type, !type.isEmpty {
            items.append(("類型", type))
        }
        if let status = anime.status, !status.isEmpty {
            items.append(("狀態", status))
        }
        if let rating = anime.rating, !rating.isEmpty {
            items.append(("分級", rating))
        }
        if let source = anime.source, !source.isEmpty {
            items.append(("來源", source))
        }
        if anime.seasonText != "-" {
            items.append(("季度", anime.seasonText))
        }
        return items
    }
}

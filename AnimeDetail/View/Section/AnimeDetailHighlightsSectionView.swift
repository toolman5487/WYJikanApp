//
//  AnimeDetailHighlightsSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailHighlightsSectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO
    
    var body: some View {
        if !highlightItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("重點資訊")
                    .font(.title3)
                    .foregroundStyle(ThemeColor.sakura)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(highlightItems, id: \.title) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .foregroundStyle(ThemeColor.textPrimary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                Text(item.value)
                                    .font(.headline)
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
        let season = viewModel.seasonText(for: anime)
        if season != "-" {
            items.append(("季度", season))
        }
        return items
    }
}

struct AnimeDetailHighlightsSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonBar(width: 88, height: 22, cornerRadius: 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonBar(width: 112, height: 72, cornerRadius: 16)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

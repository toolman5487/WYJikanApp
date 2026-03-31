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
                                    .font(.subheadline)
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
                            .frame(minHeight: 64, alignment: .leading)
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
        let type = viewModel.typeDisplayText(for: anime)
        if type != "-" {
            items.append(("類型", type))
        }
        let status = viewModel.statusDisplayText(for: anime)
        if status != "-" {
            items.append(("狀態", status))
        }
        let rating = viewModel.ratingDisplayText(for: anime)
        if rating != "-" {
            items.append(("分級", rating))
        }
        let source = viewModel.sourceDisplayText(for: anime)
        if source != "-" {
            items.append(("來源", source))
        }
        return items
    }
}

struct AnimeDetailHighlightsSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonBar(width: 112, height: 72, cornerRadius: 16)
                    }
                }
            }
        }
    }
}

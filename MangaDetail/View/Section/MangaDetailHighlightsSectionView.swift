//
//  MangaDetailHighlightsSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailHighlightsSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

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
        let type = viewModel.mangaTypeDisplayText(for: manga)
        if type != "-" {
            items.append(("類型", type))
        }
        let status = viewModel.mangaStatusDisplayText(for: manga)
        if status != "-" {
            items.append(("狀態", status))
        }
        let vol = viewModel.volumesDisplayText(for: manga)
        if vol != "-" && vol != "未知" {
            items.append(("卷數", vol))
        }
        let ch = viewModel.chaptersDisplayText(for: manga)
        if ch != "-" && ch != "未知" {
            items.append(("話數", ch))
        }
        return items
    }
}

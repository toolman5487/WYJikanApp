//
//  MangaDetailSynopsisSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailSynopsisSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    var body: some View {
        AnimeDetailSectionCard(sectionTitle) {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.hasSynopsis(for: manga) {
                    Text(viewModel.synopsisDisplayText(for: manga))
                        .font(.body)
                        .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if viewModel.hasThemes(for: manga) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.themeDisplayItems(for: manga)) { theme in
                                Text(theme.name ?? "—")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(ThemeColor.textPrimary)
                                    .lineLimit(1)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .frame(minHeight: 44)
                                    .background(ThemeColor.sakura)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    private var sectionTitle: String {
        if viewModel.hasSynopsis(for: manga) {
            return "作品簡介"
        }
        return "主題"
    }
}

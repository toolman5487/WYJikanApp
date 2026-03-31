//
//  AnimeDetailSynopsisSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailSynopsisSectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO
    
    var body: some View {
        AnimeDetailSectionCard(sectionTitle) {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.hasSynopsis(for: anime) {
                    Text(viewModel.synopsisDisplayText(for: anime))
                        .font(.body)
                        .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if viewModel.hasThemes(for: anime) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.themeDisplayItems(for: anime)) { theme in
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
        if viewModel.hasSynopsis(for: anime) {
            return "作品簡介"
        }
        return "主題"
    }
}

struct AnimeDetailSynopsisSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

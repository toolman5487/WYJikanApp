//
//  AnimeDetailEpisodesEntrySectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import SwiftUI

struct AnimeDetailEpisodesEntrySectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO
    let service: any AnimeDetailServicing

    var body: some View {
        NavigationLink {
            AnimeDetailEpisodesListView(
                malId: anime.malId,
                animeTitle: viewModel.displayTitle(for: anime),
                service: service
            )
        } label: {
            AnimeDetailSectionCard("集數") {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.episodesSummaryTitle(for: anime))
                            .font(.headline)
                            .foregroundStyle(ThemeColor.textPrimary)

                        Text(viewModel.episodesSummarySubtitle(for: anime))
                            .font(.footnote)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(ThemeColor.sakura)
                }
                .padding(.vertical, 4)
            }
        }
        .buttonStyle(.plain)
    }
}

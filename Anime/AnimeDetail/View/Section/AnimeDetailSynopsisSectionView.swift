//
//  AnimeDetailSynopsisSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailSynopsisSectionView: View {
    @ObservedObject var viewModel: AnimeDetailViewModel
    @ObservedObject private var synopsisTranslationViewModel: SynopsisTranslationViewModel
    let anime: AnimeDetailDTO

    init(viewModel: AnimeDetailViewModel, anime: AnimeDetailDTO) {
        self.viewModel = viewModel
        self.anime = anime
        _synopsisTranslationViewModel = ObservedObject(
            wrappedValue: viewModel.synopsisTranslationViewModel
        )
    }

    var body: some View {
        AnimeDetailSectionCard(
            sectionTitle,
            titleAccessory: {
                SynopsisTranslationButton(
                    state: synopsisTranslationViewModel.state,
                    action: { viewModel.requestSynopsisTranslation(for: anime) }
                )
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                TranslatedSynopsisTextView(
                    originalText: originalSynopsisText,
                    translationState: synopsisTranslationViewModel.state
                )

                if let url = viewModel.malWorkPageURL(for: anime) {
                    MALWorkPageOpenButton(url: url)
                }
            }
        }
    }

    private var sectionTitle: String {
        "作品簡介"
    }

    private var originalSynopsisText: String {
        viewModel.synopsisDisplayText(for: anime)
    }
}

//
//  MangaDetailSynopsisSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailSynopsisSectionView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: MangaDetailViewModel
    @ObservedObject private var synopsisTranslationViewModel: SynopsisTranslationViewModel
    let manga: MangaDetailDTO

    // MARK: - Lifecycle

    init(viewModel: MangaDetailViewModel, manga: MangaDetailDTO) {
        self.viewModel = viewModel
        self.manga = manga
        _synopsisTranslationViewModel = ObservedObject(
            wrappedValue: viewModel.synopsisTranslationViewModel
        )
    }

    // MARK: - Body

    var body: some View {
        AnimeDetailSectionCard(
            sectionTitle,
            titleAccessory: {
                SynopsisTranslationButton(
                    state: synopsisTranslationViewModel.state,
                    action: { viewModel.requestSynopsisTranslation(for: manga) }
                )
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                TranslatedSynopsisTextView(
                    originalText: originalSynopsisText,
                    translationState: synopsisTranslationViewModel.state
                )

                if let url = viewModel.malWorkPageURL(for: manga) {
                    MALWorkPageOpenButton(url: url)
                }
            }
        }
    }

    // MARK: - Private Methods

    private var sectionTitle: String {
        "作品簡介"
    }

    private var originalSynopsisText: String {
        viewModel.synopsisDisplayText(for: manga)
    }
}

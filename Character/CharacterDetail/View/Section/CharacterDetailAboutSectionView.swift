//
//  CharacterDetailAboutSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailAboutSectionView: View {
    let viewModel: CharacterDetailViewModel
    @ObservedObject private var synopsisTranslationViewModel: SynopsisTranslationViewModel
    let character: CharacterDetailDTO

    init(viewModel: CharacterDetailViewModel, character: CharacterDetailDTO) {
        self.viewModel = viewModel
        self.character = character
        _synopsisTranslationViewModel = ObservedObject(
            wrappedValue: viewModel.synopsisTranslationViewModel
        )
    }

    var body: some View {
        if let about = viewModel.aboutText(for: character) {
            AnimeDetailSectionCard(
                "角色簡介",
                titleAccessory: {
                    SynopsisTranslationButton(
                        state: synopsisTranslationViewModel.state,
                        idleTitle: "翻譯介紹",
                        translatedTitle: "重新翻譯",
                        action: { viewModel.requestSynopsisTranslation(for: character) }
                    )
                }
            ) {
                TranslatedSynopsisTextView(
                    originalText: about,
                    translationState: synopsisTranslationViewModel.state
                )
                .lineSpacing(4)
                .textSelection(.enabled)
            }
        }
    }
}

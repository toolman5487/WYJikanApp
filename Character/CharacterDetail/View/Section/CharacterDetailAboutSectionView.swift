//
//  CharacterDetailAboutSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailAboutSectionView: View {
    let viewModel: CharacterDetailViewModel
    let character: CharacterDetailDTO

    var body: some View {
        if let about = viewModel.aboutText(for: character) {
            AnimeDetailSectionCard("角色簡介") {
                Text(about)
                    .font(.body)
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                    .lineSpacing(4)
                    .textSelection(.enabled)
            }
        }
    }
}

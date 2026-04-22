//
//  CharacterDetailInfoSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailInfoSectionView: View {
    let viewModel: CharacterDetailViewModel
    let character: CharacterDetailDTO

    var body: some View {
        AnimeDetailSectionCard("角色資訊") {
            VStack(alignment: .leading, spacing: 10) {
                AnimeDetailInfoRow(title: "日文名", value: character.nameKanji ?? "-")
                AnimeDetailInfoRow(title: "英文名", value: character.name ?? "-")
                AnimeDetailInfoRow(title: "收藏", value: viewModel.favoritesText(for: character))

                if let nicknames = viewModel.nicknamesText(for: character) {
                    AnimeDetailInfoRow(title: "別名", value: nicknames)
                }
            }
        }
    }
}

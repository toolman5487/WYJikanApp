//
//  MangaDetailPublicationSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

struct MangaDetailPublicationSectionView: View {
    let viewModel: MangaDetailViewModel
    let manga: MangaDetailDTO

    var body: some View {
        let authorsText = viewModel.joinedNames(from: manga.authors)
        let serializationsText = viewModel.joinedNames(from: manga.serializations)
        let genresText = viewModel.joinedNames(from: manga.genres)
        let demographicsText = viewModel.joinedNames(from: manga.demographics)

        AnimeDetailSectionCard("出版資訊") {
            VStack(spacing: 10) {
                AnimeDetailInfoRow(title: "作者", value: authorsText)
                AnimeDetailInfoRow(title: "連載", value: serializationsText)
                AnimeDetailInfoRow(title: "類型", value: genresText)
                AnimeDetailInfoRow(title: "族群", value: demographicsText)
            }
        }
    }
}

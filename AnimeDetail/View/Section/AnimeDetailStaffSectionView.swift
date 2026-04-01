//
//  AnimeDetailStaffSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailStaffSectionView: View {
    let viewModel: AnimeDetailViewModel
    let anime: AnimeDetailDTO

    var body: some View {
        let studioText = viewModel.joinedNames(from: anime.studios)
        let producerText = viewModel.joinedNames(from: anime.producers)
        let genreText = viewModel.joinedNames(from: anime.genres)
        
        AnimeDetailSectionCard("製作資訊") {
            VStack(spacing: 10) {
                AnimeDetailInfoRow(title: "工作室", value: studioText)
                AnimeDetailInfoRow(title: "製作", value: producerText)
                AnimeDetailInfoRow(title: "類型", value: genreText)
            }
        }
    }
}

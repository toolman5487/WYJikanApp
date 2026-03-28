//
//  AnimeDetailStaffSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailStaffSectionView: View {
    let anime: AnimeDetailDTO
    
    var body: some View {
        let studioText = anime.joinedNames(from: anime.studios)
        let producerText = anime.joinedNames(from: anime.producers)
        let genreText = anime.joinedNames(from: anime.genres)
        
        AnimeDetailSectionCard("製作資訊") {
            VStack(spacing: 10) {
                AnimeDetailInfoRow(title: "工作室", value: studioText)
                AnimeDetailInfoRow(title: "製作", value: producerText)
                AnimeDetailInfoRow(title: "類型", value: genreText)
            }
        }
    }
}

struct AnimeDetailStaffSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(titleWidth: 88, rowCount: 3)
    }
}

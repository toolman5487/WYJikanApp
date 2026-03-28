//
//  AnimeDetailBasicInfoSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct AnimeDetailBasicInfoSectionView: View {
    let anime: AnimeDetailDTO
    
    var body: some View {
        AnimeDetailSectionCard("基本資訊") {
            VStack(spacing: 10) {
                AnimeDetailInfoRow(title: "集數", value: anime.episodes.map(String.init) ?? "-")
                AnimeDetailInfoRow(title: "播出季度", value: anime.seasonText)
                AnimeDetailInfoRow(title: "播出時間", value: anime.broadcast?.string ?? anime.aired?.string ?? "-")
                AnimeDetailInfoRow(title: "片長", value: anime.duration ?? "-")
            }
        }
    }
}

struct AnimeDetailBasicInfoSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(titleWidth: 88, rowCount: 4)
    }
}

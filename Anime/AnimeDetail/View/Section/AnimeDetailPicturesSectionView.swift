//
//  AnimeDetailPicturesSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import Foundation
import SwiftUI

struct AnimeDetailPicturesSectionView: View {

    let viewModel: AnimeDetailViewModel
    let onTapImage: ((Int) -> Void)?

    init(viewModel: AnimeDetailViewModel, onTapImage: ((Int) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onTapImage = onTapImage
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        AnimeDetailSectionCard("劇照") {
            LazyVGrid(columns: gridColumns, alignment: .center, spacing: 12) {
                ForEach(Array(viewModel.pictureItems.enumerated()), id: \.element.id) { index, item in
                    DetailPictureGridItemView(url: item.url) {
                        onTapImage?(index)
                    }
                }
            }
        }
    }
}

struct DetailPictureGridItemView: View {

    private static let aspectRatio: CGFloat = 2.0 / 3.0
    private static let cornerRadius: CGFloat = 12

    let url: URL
    let onTap: () -> Void

    var body: some View {
        Rectangle()
            .fill(Color(.systemBackground))
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    RemotePosterImageView(
                        url: url,
                        contentMode: .fill,
                        fixedSize: proxy.size
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    AnimeDetailPicturesSectionView(viewModel: AppDependencies.live.makeAnimeDetailViewModel(malId: 1))
        .padding()
}

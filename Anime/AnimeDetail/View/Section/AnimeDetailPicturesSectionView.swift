//
//  AnimeDetailPicturesSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

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
                    RemotePosterImageView(url: item.url)
                        .aspectRatio(2.0 / 3.0, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTapImage?(index)
                        }
                }
            }
        }
    }
}

#Preview {
    AnimeDetailPicturesSectionView(viewModel: AnimeDetailViewModel(malId: 1))
        .padding()
}

//
//  MangaDetailPicturesSectionView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct MangaDetailPicturesSectionView: View {
    let viewModel: MangaDetailViewModel
    let onTapImage: (Int) -> Void

    var body: some View {
        if viewModel.canShowFullPictureList {
            AnimeDetailLinkedSection(
                title: "圖片",
                actionTitle: "查看全部"
            ) {
                MangaDetailPicturesListView(
                    viewModel: viewModel,
                    onTapImage: onTapImage
                )
            } content: {
                pictureGrid(items: viewModel.previewPictureItems)
            }
        } else {
            AnimeDetailSectionCard("圖片") {
                pictureGrid(items: viewModel.pictureItems)
            }
        }
    }

    @ViewBuilder
    private func pictureGrid(items: [MangaDetailPictureItem]) -> some View {
        DetailPictureGridLayout {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                DetailPictureGridItemView(url: item.url) {
                    onTapImage(index)
                }
            }
        }
    }
}

struct MangaDetailPicturesListView: View {
    let viewModel: MangaDetailViewModel
    let onTapImage: (Int) -> Void

    var body: some View {
        DetailPictureGridLayout(embedInScrollView: true) {
            ForEach(Array(viewModel.pictureItems.enumerated()), id: \.element.id) { index, item in
                DetailPictureGridItemView(url: item.url) {
                    onTapImage(index)
                }
            }
        }
        .navigationTitle("圖片")
        .navigationBarTitleDisplayMode(.inline)
    }
}

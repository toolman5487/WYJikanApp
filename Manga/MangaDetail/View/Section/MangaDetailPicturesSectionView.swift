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

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    @ViewBuilder
    private func pictureGrid(items: [MangaDetailPictureItem]) -> some View {
        LazyVGrid(columns: gridColumns, alignment: .center, spacing: 12) {
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

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, alignment: .center, spacing: 12) {
                ForEach(Array(viewModel.pictureItems.enumerated()), id: \.element.id) { index, item in
                    DetailPictureGridItemView(url: item.url) {
                        onTapImage(index)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("圖片")
        .navigationBarTitleDisplayMode(.inline)
    }
}

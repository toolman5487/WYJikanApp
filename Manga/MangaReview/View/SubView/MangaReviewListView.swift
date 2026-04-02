//
//  MangaReviewListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MangaReviewListView: View {

    @ObservedObject var viewModel: MangaReviewViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(Array(viewModel.reviews.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Divider()
                    }
                    MangaReviewRowView(viewModel: viewModel, entry: entry)
                }

                if viewModel.hasNextPage {
                    Button {
                        Task { await viewModel.loadMore() }
                    } label: {
                        HStack {
                            if viewModel.isLoadingMore {
                                ProgressView()
                            }
                            Text("載入更多")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(ThemeColor.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .background(ThemeColor.sakura)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(viewModel.isLoadingMore)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

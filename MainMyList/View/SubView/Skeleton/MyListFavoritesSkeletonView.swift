//
//  MyListFavoritesSkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MyListFavoritesSkeletonView: View {

    // MARK: - Properties

    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 3
    )

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MyListSectionHeaderSkeletonView(titleWidth: 112, subtitleWidth: 188)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<9, id: \.self) { _ in
                    MyListFavoriteItemSkeletonView()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MyListFavoriteItemSkeletonView

private struct MyListFavoriteItemSkeletonView: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .aspectRatio(0.72, contentMode: .fit)
                .overlay {
                    ShimmerView()
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            SkeletonBar(width: nil, height: 12, cornerRadius: 4)
            SkeletonBar(width: 56, height: 12, cornerRadius: 4)
        }
    }
}

#Preview {
    ScrollView {
        MyListFavoritesSkeletonView()
            .padding()
    }
}

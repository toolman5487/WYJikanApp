//
//  MyListFavoritesSkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MyListFavoritesSkeletonView: View {
    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 14),
        count: 3
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MyListSectionHeaderSkeletonView(titleWidth: 112, subtitleWidth: 188)

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(0..<9, id: \.self) { _ in
                    MyListFavoriteItemSkeletonView()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MyListFavoriteItemSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemGray5))
                .aspectRatio(0.72, contentMode: .fit)
                .overlay {
                    ShimmerView()
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            SkeletonBar(width: nil, height: 13, cornerRadius: 5)
            SkeletonBar(width: 58, height: 11, cornerRadius: 4)
        }
    }
}

#Preview {
    ScrollView {
        MyListFavoritesSkeletonView()
            .padding()
    }
}

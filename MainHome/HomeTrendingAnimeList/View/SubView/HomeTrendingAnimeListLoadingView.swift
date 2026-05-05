//
//  HomeTrendingAnimeListLoadingView.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import SwiftUI

struct HomeTrendingAnimeListLoadingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(height: 340)

            HStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemGray5))
                            .frame(height: 190)
                        SkeletonBar(width: 120, height: 18, cornerRadius: 8)
                        SkeletonBar(width: 90, height: 12, cornerRadius: 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: 82, height: 120)

                    VStack(alignment: .leading, spacing: 10) {
                        SkeletonBar(width: 160, height: 18, cornerRadius: 8)
                        SkeletonBar(width: 120, height: 14, cornerRadius: 8)
                        SkeletonBar(width: 200, height: 12, cornerRadius: 8)
                        SkeletonBar(width: 180, height: 12, cornerRadius: 8)
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

//
//  GenreAnimeListSkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/10.
//

import SwiftUI

struct GenreAnimeListSkeletonView: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBar(width: 120, height: 24, cornerRadius: 8)
                        .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .frame(width: 240 * (2.0 / 3.0), height: 240)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}

#Preview {
    GenreAnimeListSkeletonView()
}

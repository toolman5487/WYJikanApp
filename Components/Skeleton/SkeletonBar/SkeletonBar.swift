//
//  SkeletonBar.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/28.
//

import SwiftUI

struct SkeletonBar: View {
    var width: CGFloat?
    let height: CGFloat
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

struct RankedMediaListLoadingView: View {

    var rowCount: Int = 6

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(0..<rowCount, id: \.self) { _ in
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: 84, height: 120)

                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonBar(width: 180, height: 16, cornerRadius: 8)
                        SkeletonBar(width: 116, height: 12, cornerRadius: 8)
                        SkeletonBar(width: 160, height: 20, cornerRadius: 8)
                        SkeletonBar(width: 132, height: 12, cornerRadius: 8)
                        SkeletonBar(width: 220, height: 12, cornerRadius: 8)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

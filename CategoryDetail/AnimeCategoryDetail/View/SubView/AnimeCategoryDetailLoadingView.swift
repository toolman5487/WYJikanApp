//
//  AnimeCategoryDetailLoadingView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct AnimeCategoryDetailLoadingView: View {

    // MARK: - Body

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: 82, height: 120)

                    VStack(alignment: .leading, spacing: 10) {
                        SkeletonBar(width: 180, height: 18, cornerRadius: 8)
                        SkeletonBar(width: 116, height: 12, cornerRadius: 8)
                        SkeletonBar(width: 160, height: 20, cornerRadius: 10)
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

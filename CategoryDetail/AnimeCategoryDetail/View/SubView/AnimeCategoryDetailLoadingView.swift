//
//  AnimeCategoryDetailLoadingView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import SwiftUI

struct AnimeCategoryDetailLoadingView: View {
    private let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBar(width: 148, height: 24, cornerRadius: 8)
                SkeletonBar(width: 220, height: 16, cornerRadius: 8)
            }

            LazyVGrid(columns: gridColumns, spacing: 18) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.systemGray5))
                            .frame(height: 220)

                        SkeletonBar(width: 120, height: 16, cornerRadius: 8)
                        SkeletonBar(width: 84, height: 12, cornerRadius: 8)
                    }
                }
            }
        }
    }
}

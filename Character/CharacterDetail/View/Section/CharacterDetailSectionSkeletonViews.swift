//
//  CharacterDetailSectionSkeletonViews.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import SwiftUI

struct CharacterDetailHeaderSectionSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.systemGray5))
            .frame(maxWidth: .infinity)
            .frame(height: 196)
    }
}

struct CharacterDetailInfoSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(rowCount: 4)
    }
}

struct CharacterDetailAboutSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonBar(width: 84, height: 22, cornerRadius: 6)
            SkeletonBar(width: nil, height: 14, cornerRadius: 4)
            SkeletonBar(width: nil, height: 14, cornerRadius: 4)
            SkeletonBar(width: 220, height: 14, cornerRadius: 4)
        }
    }
}

struct CharacterDetailHorizontalCardsSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonBar(width: 84, height: 22, cornerRadius: 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            SkeletonBar(width: 112, height: 156, cornerRadius: 14)
                            SkeletonBar(width: 112, height: 12, cornerRadius: 4)
                            SkeletonBar(width: 64, height: 10, cornerRadius: 4)
                        }
                    }
                }
            }
        }
    }
}

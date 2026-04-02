//
//  MangaReviewSkeletonViews.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

// MARK: - List

struct MangaReviewListSkeletonView: View {

    private static let rowCount = 6

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(0..<Self.rowCount, id: \.self) { index in
                    if index > 0 {
                        Divider()
                    }
                    MangaReviewRowSkeletonView()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Row

struct MangaReviewRowSkeletonView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerPlaceholder
            tagsPlaceholder
            bodyPlaceholder
            buttonPlaceholder
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Private

    private var headerPlaceholder: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
                .overlay {
                    ShimmerView()
                }
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                SkeletonBar(width: 140, height: 15, cornerRadius: 6)
                SkeletonBar(width: 96, height: 12, cornerRadius: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            SkeletonBar(width: 40, height: 22, cornerRadius: 6)
        }
    }

    private var tagsPlaceholder: some View {
        HStack(spacing: 10) {
            SkeletonBar(width: 72, height: 36, cornerRadius: 18)
            SkeletonBar(width: 96, height: 36, cornerRadius: 18)
            SkeletonBar(width: 64, height: 36, cornerRadius: 18)
        }
    }

    private var bodyPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            SkeletonBar(width: nil, height: 14, cornerRadius: 4)
            SkeletonBar(width: 160, height: 14, cornerRadius: 4)
        }
    }

    private var buttonPlaceholder: some View {
        SkeletonBar(width: nil, height: 44, cornerRadius: 12)
    }
}

#Preview("List") {
    MangaReviewListSkeletonView()
}

#Preview("Row") {
    ScrollView {
        MangaReviewRowSkeletonView()
            .padding()
    }
}

//
//  AnimeDetailSectionSkeletonViews.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

// MARK: - Header

struct AnimeDetailHeaderSectionSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.systemGray5))
            .frame(maxWidth: .infinity)
            .frame(height: 196)
    }
}

// MARK: - Highlights

struct AnimeDetailHighlightsSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonBar(width: 112, height: 72, cornerRadius: 16)
                    }
                }
            }
        }
    }
}

// MARK: - Basic Info

struct AnimeDetailBasicInfoSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(rowCount: 5)
    }
}

// MARK: - Score

struct AnimeDetailScoreSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(rowCount: 5)
    }
}

// MARK: - Trailer

struct AnimeDetailTrailerSectionSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.systemGray5))
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Synopsis

struct AnimeDetailSynopsisSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Staff

struct AnimeDetailStaffSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionCardSkeleton(rowCount: 3)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonBar(width: 88, height: 40, cornerRadius: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Pictures

struct AnimeDetailPicturesSectionSkeletonView: View {

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(.systemGray4))
                .frame(width: 56, height: 22)
            LazyVGrid(columns: gridColumns, alignment: .center, spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray5))
                        .aspectRatio(2.0 / 3.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

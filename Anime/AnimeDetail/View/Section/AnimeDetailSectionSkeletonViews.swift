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

// MARK: - Episodes

struct AnimeDetailEpisodesEntrySectionSkeletonView: View {
    var body: some View {
        AnimeDetailSectionCard("集數") {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBar(width: 136, height: 20, cornerRadius: 8)
                    SkeletonBar(width: 220, height: 16, cornerRadius: 8)
                }

                Spacer(minLength: 0)

                SkeletonBar(width: 24, height: 24, cornerRadius: 12)
            }
            .padding(.vertical, 4)
        }
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

// MARK: - Characters

struct AnimeDetailCharactersSectionSkeletonView: View {
    var body: some View {
        AnimeDetailHorizontalCardSectionSkeletonView(titleWidth: 96, actionWidth: 64)
    }
}

// MARK: - Staff

struct AnimeDetailStaffSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionCardSkeleton(rowCount: 3)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonBar(width: 88, height: 40, cornerRadius: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Recommendations

struct AnimeDetailRecommendationsSectionSkeletonView: View {
    var body: some View {
        AnimeDetailHorizontalCardSectionSkeletonView(titleWidth: 112, actionWidth: 64)
    }
}

// MARK: - Shared

struct AnimeDetailHorizontalCardSectionSkeletonView: View {
    let titleWidth: CGFloat
    let actionWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                SkeletonBar(width: titleWidth, height: 24, cornerRadius: 8)

                Spacer(minLength: 0)

                SkeletonBar(width: actionWidth, height: 16, cornerRadius: 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            SkeletonBar(width: 160, height: 240, cornerRadius: 16)
                            SkeletonBar(width: 136, height: 16, cornerRadius: 8)
                            SkeletonBar(width: 104, height: 16, cornerRadius: 8)
                        }
                        .frame(width: 160, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemGray4))
                .frame(width: 56, height: 24)
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

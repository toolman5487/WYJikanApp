//
//  MangaDetailSectionSkeletonViews.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import SwiftUI

// MARK: - Header

struct MangaDetailHeaderSectionSkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(width: 132, height: 196)
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.systemGray5))
                    .frame(height: 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.systemGray5))
                    .frame(width: 160, height: 16)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.systemGray5))
                    .frame(width: 88, height: 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Highlights

struct MangaDetailHighlightsSectionSkeletonView: View {
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

// MARK: - Score

struct MangaDetailScoreSectionSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(rowCount: 6)
    }
}

// MARK: - Synopsis

struct MangaDetailSynopsisSectionSkeletonView: View {
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

// MARK: - Publication

struct MangaDetailPublicationSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionCardSkeleton(rowCount: 4)
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

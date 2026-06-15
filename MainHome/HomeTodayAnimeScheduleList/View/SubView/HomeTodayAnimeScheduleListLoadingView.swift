//
//  HomeTodayAnimeScheduleListLoadingView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import SwiftUI

// MARK: - HomeTodayAnimeScheduleListLoadingView

struct HomeTodayAnimeScheduleListLoadingView: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBar(width: 72, height: 24, cornerRadius: 8)

                    ForEach(0..<2, id: \.self) { _ in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray5))
                                .frame(width: 76, height: 112)

                            VStack(alignment: .leading, spacing: 12) {
                                SkeletonBar(width: 160, height: 16, cornerRadius: 8)
                                SkeletonBar(width: 120, height: 16, cornerRadius: 8)
                                SkeletonBar(width: 192, height: 12, cornerRadius: 8)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
    }
}

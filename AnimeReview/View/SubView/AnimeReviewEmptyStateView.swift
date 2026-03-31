//
//  AnimeReviewEmptyStateView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct AnimeReviewEmptyStateView: View {

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            VStack(spacing: 16) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 60))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(ThemeColor.sakura)
                VStack(spacing: 8) {
                    Text("尚無評論")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 480)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AnimeReviewEmptyStateView()
}

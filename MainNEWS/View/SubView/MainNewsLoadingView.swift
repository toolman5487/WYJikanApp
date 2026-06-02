//
//  MainNewsLoadingView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: 96, height: 72)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            SkeletonBar(width: index.isMultiple(of: 2) ? 104 : 132, height: 12, cornerRadius: 6)
                            SkeletonBar(width: 56, height: 12, cornerRadius: 6)
                        }

                        SkeletonBar(width: 188, height: 16, cornerRadius: 8)
                        SkeletonBar(width: 232, height: 16, cornerRadius: 8)
                        SkeletonBar(width: 164, height: 12, cornerRadius: 6)
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

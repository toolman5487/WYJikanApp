//
//  MyListHeaderSkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/21.
//

import SwiftUI

struct MyListHeaderSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                Circle()
                    .fill(ThemeColor.sakuraGlass)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "heart.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(ThemeColor.sakura)
                    }

                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBar(width: 156, height: 24, cornerRadius: 8)
                    SkeletonBar(width: 220, height: 16, cornerRadius: 4)
                }

                Spacer()
            }

            MyListHeroCardSkeletonView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MyListHeroCardSkeletonView: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(ThemeColor.sakuraGlass)
                .overlay {
                    ShimmerView()
                }

            VStack(alignment: .leading, spacing: 12) {
                SkeletonBar(width: 92, height: 16, cornerRadius: 8)
                SkeletonBar(width: 220, height: 28, cornerRadius: 8)
                SkeletonBar(width: 164, height: 16, cornerRadius: 4)
            }
            .padding(24)
        }
        .frame(height: 168)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

#Preview {
    MyListHeaderSkeletonView()
        .padding()
}
